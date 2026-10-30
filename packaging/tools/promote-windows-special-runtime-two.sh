#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
e=$1
index="$e/source-index.tsv"
backup="$e/source-index.pre-special-runtime-two.tsv"
verification="$e/special-runtime-two-verification-v1.tsv"
for required in "$index" "$e/runtime-manifest.tsv" "$e/license-manifest.tsv" \
  "$e/remaining-source-audit-summary-v1.tsv" "$e/msys2-source-package-inspection.tsv" \
  "$e/remaining-license-candidate-coverage-v1.tsv" "$e/remaining-root-license-staging-v2.tsv" \
  "$e/remaining-nested-license-build-triage-v4.tsv" "$e/special-source-archive-audit-v1.tsv" \
  "$e/special-source-license-candidates-v1.tsv"; do
  [ -f "$required" ] || { echo "Missing: $required" >&2; exit 1; }
done
for output in "$backup" "$verification"; do
  [ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 1; }
done

scratch=$(mktemp -d "$e/.special-two-promotion.XXXXXX")
cleanup() { rm -rf "$scratch"; }
trap cleanup EXIT

cat > "$scratch/packages.tsv" <<'ROWS'
package	version	source_sha256	patch_count	patch_set_sha256	runtime_file	runtime_sha256	classification
mingw-w64-x86_64-libxml2	2.15.3-1	5328b89cd2b1b475da12fddd1792c9ea2f1e6dbb09504402b62ada78539f3d86	4	d17d2e8b7e379c243a89c9e37187543f46847943e5e18868071d939a0accb2a3	libxml2-16.dll	beb148bc5c12cdccf7a28767981c9c3da8b3f2d607f03a1a3458d128fd650089	TEST_NOTICE_EXCLUDED_RUNTIME_ROOT_TEXT_STAGED
mingw-w64-x86_64-gettext-runtime	1.0-1	cca0d0c8f60353faccc5ad40405240014e4a7ccc8b1c6ca9f4626aef3097d26e	6	7b65e030f78ce071b1e243d394f48113f73e61db0e0da638dbb6f9093650bb58	libintl-8.dll	0537c3dd2378218508ebe3cc416d72a99ee2d24ae1c5525e23458f32544ef861	FOUR_RUNTIME_TEXTS_STAGED_TWELVE_SPLIT_PACKAGE_TEXTS_EXCLUDED
ROWS

check_sha() {
  local actual
  actual=$(sha256sum "$1"); actual=${actual%% *}
  [ "$actual" = "$2" ] || { echo "SHA-256 mismatch: $1" >&2; exit 1; }
}

printf 'package\tversion\tsource_sha256\tpatch_count\tpatch_set_sha256\truntime_file\truntime_sha256\tlicense_review\tstatus\n' \
  > "$scratch/verification.tsv"

while IFS=$'\t' read -r package version source_sha patch_count patch_set_sha runtime_file runtime_sha classification; do
  [ "$package" = package ] && continue
  archive="$e/source-packages/$package-$version.src.tar.zst"
  check_sha "$archive" "$source_sha"
  source_url=$(awk -F '\t' -v p="$package" -v v="$version" -v h="$source_sha" '
    NR > 1 && $1 == p && $2 == v {if ($3 != "SPECIAL_ARCHIVE" || $5 != h || $7 != "UPSTREAM_SHA_MATCH" || $8 != "LICENSE_REVIEW_PENDING") exit 1; print $4; n++}
    END {if (n != 1) exit 1}' "$e/remaining-source-audit-summary-v1.tsv")
  awk -F '\t' -v p="$package" -v v="$version" -v u="$source_url" '
    NR > 1 && $1 == p && $2 == v {if ($5 != u || $6 != "MISSING" || $7 != "PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION") exit 1; n++}
    END {if (n != 1) exit 1}' "$index"
  awk -F '\t' -v p="$package" -v v="$version" -v h="$source_sha" '
    NR > 1 && $1 == p && $2 == v {if ($3 != h || $6 != $7 || $9 != "UPSTREAM_SHA_MATCH") exit 1; n++}
    END {if (p ~ /libxml2$/ && n != 2) exit 1; if (p ~ /gettext-runtime$/ && n != 1) exit 1}' \
    "$e/special-source-archive-audit-v1.tsv"
  awk -F '\t' -v p="$package" -v v="$version" -v c="$patch_count" '
    NR > 1 && $1 == p && $2 == v {if ($5 != c) exit 1; n++}
    END {if (n != 1) exit 1}' "$e/msys2-source-package-inspection.tsv"

  extract_dir="$scratch/$package"; mkdir -p "$extract_dir"
  tar xf "$archive" -C "$extract_dir"
  outer_root=$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d | head -n1)
  : > "$extract_dir/patches.tsv"
  for patch in "$outer_root"/*.patch; do
    patch_sha=$(sha256sum "$patch"); patch_sha=${patch_sha%% *}
    printf '%s\t%s\n' "$(basename "$patch")" "$patch_sha" >> "$extract_dir/patches.tsv"
  done
  sort -o "$extract_dir/patches.tsv" "$extract_dir/patches.tsv"
  [ "$(wc -l < "$extract_dir/patches.tsv" | tr -d '[:space:]')" = "$patch_count" ]
  check_sha "$extract_dir/patches.tsv" "$patch_set_sha"

  check_sha "/mingw64/bin/$runtime_file" "$runtime_sha"
  awk -F '\t' -v p="$package" -v d="$runtime_file" -v h="$runtime_sha" '
    NR > 1 && $1 == d && $2 == h && $5 == p {n++} END {if (n != 1) exit 1}' "$e/runtime-manifest.tsv"

  if [ "$package" = mingw-w64-x86_64-libxml2 ]; then
    awk -F '\t' -v p="$package" -v v="$version" 'NR > 1 && $1 == p && $2 == v {if ($4 != 1 || $5 != 2) exit 1; n++} END {if (n != 1) exit 1}' "$e/remaining-license-candidate-coverage-v1.tsv"
    staged_path=$(awk -F '\t' -v p="$package" -v h=5d4873884a890122a4b9b20ad56ac6f7da1d796a5bfcf04a427970ac96217626 '
      NR > 1 && $1 == p {if ($5 != h || $7 != "EXACT_TEXT_ALREADY_STAGED") exit 1; print $6; n++} END {if (n != 1) exit 1}' "$e/remaining-root-license-staging-v2.tsv")
    check_sha "$e/$staged_path" 5d4873884a890122a4b9b20ad56ac6f7da1d796a5bfcf04a427970ac96217626
    awk -F '\t' -v p="$package" 'NR > 1 && $1 == p {if ($5 != "SOURCE_ONLY_SAMPLE_OR_TEST" || $4 != "d6a2cb265a0a249a234b89eeffa7f316ebe5bff546672a0a2b1a861dd2238460") exit 1; n++} END {if (n != 2) exit 1}' "$e/remaining-nested-license-build-triage-v4.tsv"
    expected_license_count=1
  else
    awk -F '\t' -v p="$package" -v v="$version" 'NR > 1 && $1 == p && $2 == v {if ($4 != 1 || $5 != 16) exit 1; n++} END {if (n != 1) exit 1}' "$e/remaining-license-candidate-coverage-v1.tsv"
    awk -F '\t' -v p="$package" 'NR > 1 && $1 == p {n[$5]++} END {if (n["RUNTIME_COMPONENT_TEXT"] != 4 || n["DIFFERENT_SPLIT_PACKAGE"] != 12) exit 1}' "$e/remaining-nested-license-build-triage-v4.tsv"
    awk -F '\t' -v p="$package" 'NR > 1 && $1 == p {if ($5 != "e79e9c8a0c85d735ff98185918ec94ed7d175efc377012787aebcf3b80f0d90b" || $7 != "ROOT_TEXT_NOT_IN_STAGED_LICENSES") exit 1; n++} END {if (n != 1) exit 1}' "$e/remaining-root-license-staging-v2.tsv"
    check_sha "$e/licenses/$package/share/licenses/gettext-runtime/COPYING" 7ef2cdfe58e0c0460657b6598b49af29d4e03c1e41cbaf0e1da1eb8ad74b95d0
    check_sha "$e/licenses/$package/share/licenses/gettext-runtime/libasprintf/COPYING" 03133addae5b99a6148c538300e6d97074453089be1423b741bd081f18e2b298
    check_sha "$e/licenses/$package/share/licenses/gettext-runtime/intl/COPYING.LIB" 20e50fe7aae3e56378ebf0417d9de904f55a0e61e4df315333e632a4d3555d95
    check_sha "$e/licenses/$package/share/licenses/gettext-runtime/libasprintf/COPYING.LIB" 20e50fe7aae3e56378ebf0417d9de904f55a0e61e4df315333e632a4d3555d95
    for fn in package_gettext-runtime package_gettext-libtextstyle package_gettext-tools; do grep -Fq "$fn" "$outer_root/PKGBUILD"; done
    expected_license_count=4
  fi
  recorded_license_count=$(awk -F '\t' -v p="$package" -v v="$version" 'NR > 1 && $1 == p && $2 == v {if ($4 != "COLLECTED") exit 1; print $3; n++} END {if (n != 1) exit 1}' "$e/license-manifest.tsv")
  actual_license_count=$(find "$e/licenses/$package" -type f | wc -l | tr -d '[:space:]')
  [ "$recorded_license_count" = "$expected_license_count" ]
  [ "$actual_license_count" = "$expected_license_count" ]

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tVERIFIED\n' "$package" "$version" "$source_sha" "$patch_count" "$patch_set_sha" "$runtime_file" "$runtime_sha" "$classification" >> "$scratch/verification.tsv"
done < "$scratch/packages.tsv"

awk -F '\t' -v OFS='\t' 'NR == FNR {if (FNR > 1) promote[$1 SUBSEP $2]=$3; next}
  FNR == 1 {print; next}
  (($1 SUBSEP $2) in promote) {$6=promote[$1 SUBSEP $2]; $7="VERIFIED"; n++}
  {print}
  END {if (n != 2) exit 1}' "$scratch/packages.tsv" "$index" > "$scratch/source-index.tsv"
cp "$index" "$backup"
mv "$scratch/source-index.tsv" "$index"
mv "$scratch/verification.tsv" "$verification"
echo "Promoted libxml2 and gettext-runtime after special archive, split-package, license, patch, and runtime verification."
