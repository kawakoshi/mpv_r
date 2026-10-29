#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
evidence_dir=$1
index="$evidence_dir/source-index.tsv"
summary="$evidence_dir/remaining-source-audit-summary-v1.tsv"
inspection="$evidence_dir/msys2-source-package-inspection.tsv"
coverage="$evidence_dir/remaining-license-candidate-coverage-v1.tsv"
root_staging="$evidence_dir/remaining-root-license-staging-v2.tsv"
license_manifest="$evidence_dir/license-manifest.tsv"
backup="$evidence_dir/source-index.pre-simple-six-promotion.tsv"
verification="$evidence_dir/simple-six-source-verification-v1.tsv"
for required in "$index" "$summary" "$inspection" "$coverage" "$root_staging" "$license_manifest"; do
  [ -f "$required" ] || { echo "Missing: $required" >&2; exit 2; }
done
for output in "$backup" "$verification"; do
  [ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 2; }
done

scratch=$(mktemp -d "$evidence_dir/.simple-six-promotion.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
printf 'package\tversion\tmsys2_source_url\tmsys2_source_sha256\tupstream_status\troot_license_text_count\tstatus\n' > "$scratch/verification.tsv"
for name in brotli libffi libunibreak pixman expat lerc; do
  package="mingw-w64-x86_64-$name"
  record=$(awk -F '\t' -v p="$package" '
    NR>1 && $1==p && $3=="STANDARD_ARCHIVE" && $7=="UPSTREAM_SHA_MATCH" {print $2 "\t" $4 "\t" $5; count++}
    END {if (count!=1) exit 1}
  ' "$summary") || { echo "Missing verified source summary: $package" >&2; exit 1; }
  version=${record%%$'\t'*}
  rest=${record#*$'\t'}
  url=${rest%%$'\t'*}
  expected_sha=${rest#*$'\t'}
  archive="$evidence_dir/source-packages/${package}-${version}.src.tar.zst"
  [ -f "$archive" ] || { echo "Missing source archive: $package" >&2; exit 1; }
  actual_sha=$(sha256sum "$archive"); actual_sha=${actual_sha%% *}
  [ "$actual_sha" = "$expected_sha" ] || { echo "MSYS2 source archive hash mismatch: $package" >&2; exit 1; }
  awk -F '\t' -v p="$package" -v v="$version" -v u="$url" '
    NR>1 && $1==p && $2==v {
      if ($5!=u || $6!="MISSING" || $7!="PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION") exit 1
      count++
    }
    END {if (count!=1) exit 1}
  ' "$index" || { echo "Unexpected source index row: $package" >&2; exit 1; }
  awk -F '\t' -v p="$package" -v v="$version" -v h="$expected_sha" '
    NR>1 && $1==p && $2==v {if ($3!=h || $5!=0) exit 1; count++}
    END {if (count!=1) exit 1}
  ' "$inspection" || { echo "Patches or archive mismatch: $package" >&2; exit 1; }
  roots=$(awk -F '\t' -v p="$package" -v v="$version" '
    NR>1 && $1==p && $2==v {if ($5!=0 || $4<1) exit 1; print $4; count++}
    END {if (count!=1) exit 1}
  ' "$coverage") || { echo "Nested license candidate or missing root text: $package" >&2; exit 1; }
  awk -F '\t' -v p="$package" -v v="$version" -v expected="$roots" '
    NR>1 && $1==p && $2==v {if ($7!="EXACT_TEXT_ALREADY_STAGED") exit 1; count++}
    END {if (count!=expected) exit 1}
  ' "$root_staging" || { echo "Unstaged source-root license text: $package" >&2; exit 1; }
  recorded_license_count=$(awk -F '\t' -v p="$package" -v v="$version" '
    NR>1 && $1==p && $2==v && $4=="COLLECTED" {print $3; count++}
    END {if (count!=1) exit 1}
  ' "$license_manifest") || { echo "Missing license manifest entry: $package" >&2; exit 1; }
  actual_license_count=$(find "$evidence_dir/licenses/$package" -type f | wc -l | tr -d '[:space:]')
  [ "$actual_license_count" = "$recorded_license_count" ] || { echo "License count mismatch: $package" >&2; exit 1; }
  member=$(tar tf "$archive" | grep '/PKGBUILD$' | head -n 1)
  [ -n "$member" ] || { echo "Missing PKGBUILD: $package" >&2; exit 1; }
  tar -xOf "$archive" "$member" | grep -Fq 'share/licenses/' || { echo "PKGBUILD lacks license staging: $package" >&2; exit 1; }
  printf '%s\t%s\t%s\t%s\tUPSTREAM_SHA_MATCH\t%s\tMSYS2_SOURCE_PACKAGE_VERIFIED\n' \
    "$package" "$version" "$url" "$expected_sha" "$roots" >> "$scratch/verification.tsv"
done

awk -F '\t' -v OFS='\t' '
  NR==FNR {if (NR>1) {key=$1 SUBSEP $2; url[key]=$3; sha[key]=$4} next}
  NR==1 {print; next}
  {key=$1 SUBSEP $2; if (key in url) {$5=url[key]; $6=sha[key]; $7="VERIFIED"; changed++} print}
  END {if (changed!=6) exit 1}
' "$scratch/verification.tsv" "$index" > "$scratch/source-index.tsv"
cp "$index" "$backup"
mv "$scratch/source-index.tsv" "$index"
mv "$scratch/verification.tsv" "$verification"
echo "Promoted six reviewed MSYS2 source-index rows; backup: $backup"
echo "Wrote: $verification"
