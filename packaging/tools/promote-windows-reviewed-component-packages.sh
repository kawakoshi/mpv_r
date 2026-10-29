#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
e=$1
index="$e/source-index.tsv"
summary="$e/remaining-source-audit-summary-v1.tsv"
inspection="$e/msys2-source-package-inspection.tsv"
coverage="$e/remaining-license-candidate-coverage-v1.tsv"
roots="$e/remaining-root-license-staging-v2.tsv"
triage="$e/remaining-nested-license-build-triage-v4.tsv"
staged_runtime="$e/remaining-nested-runtime-staging-v2.tsv"
license_manifest="$e/license-manifest.tsv"
runtime="$e/runtime-manifest.tsv"
backup="$e/source-index.pre-reviewed-four-promotion.tsv"
verification="$e/reviewed-four-source-verification-v1.tsv"
for required in "$index" "$summary" "$inspection" "$coverage" "$roots" "$triage" "$staged_runtime" "$license_manifest" "$runtime"; do
  [ -f "$required" ] || { echo "Missing: $required" >&2; exit 2; }
done
for output in "$backup" "$verification"; do
  [ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 2; }
done

scratch=$(mktemp -d "$e/.reviewed-four-promotion.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
printf 'package\tversion\tmsys2_source_url\tmsys2_source_sha256\tsource_kind\tpatch_count\troot_license_texts\tnested_license_texts\tstatus\n' > "$scratch/verification.tsv"
for name in pcre2 whisper.cpp libtiff libvpl; do
  package="mingw-w64-x86_64-$name"
  case "$name" in
    pcre2) source_kind=STANDARD_ARCHIVE; upstream_status=UPSTREAM_SHA_MATCH; patch_count=0; nested_count=1; nested_decision=RUNTIME_COMPONENT_TEXT; dll=libpcre2-8-0.dll ;;
    whisper.cpp) source_kind=PINNED_GIT; upstream_status=PINNED_REF_PRESENT_NEEDS_LICENSE_REVIEW; patch_count=0; nested_count=5; nested_decision=SOURCE_ONLY_SAMPLE_OR_TEST; dll=libwhisper-1.dll ;;
    libtiff) source_kind=STANDARD_ARCHIVE; upstream_status=UPSTREAM_SHA_MATCH; patch_count=1; nested_count=3; nested_decision=SOURCE_ONLY_SAMPLE_OR_TEST; dll=libtiff-6.dll ;;
    libvpl) source_kind=STANDARD_ARCHIVE; upstream_status=UPSTREAM_SHA_MATCH; patch_count=3; nested_count=15; nested_decision=SOURCE_ONLY_SAMPLE_OR_TEST; dll=libvpl-2.dll ;;
  esac
  record=$(awk -F '\t' -v p="$package" -v k="$source_kind" -v s="$upstream_status" '
    NR>1 && $1==p && $3==k && $7==s {print $2 "\t" $4 "\t" $5; count++}
    END {if (count!=1) exit 1}
  ' "$summary") || { echo "Missing verified source summary: $package" >&2; exit 1; }
  version=${record%%$'\t'*}; rest=${record#*$'\t'}
  url=${rest%%$'\t'*}; expected_sha=${rest#*$'\t'}
  archive="$e/source-packages/${package}-${version}.src.tar.zst"
  [ -f "$archive" ] || { echo "Missing source archive: $package" >&2; exit 1; }
  actual_sha=$(sha256sum "$archive"); actual_sha=${actual_sha%% *}
  [ "$actual_sha" = "$expected_sha" ] || { echo "Source archive SHA mismatch: $package" >&2; exit 1; }
  awk -F '\t' -v p="$package" -v v="$version" -v u="$url" '
    NR>1 && $1==p && $2==v {if ($5!=u || $6!="MISSING" || $7!="PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION") exit 1; count++}
    END {if (count!=1) exit 1}
  ' "$index" || { echo "Unexpected source index state: $package" >&2; exit 1; }
  awk -F '\t' -v p="$package" -v v="$version" -v h="$expected_sha" -v n="$patch_count" '
    NR>1 && $1==p && $2==v {if ($3!=h || $5!=n) exit 1; count++}
    END {if (count!=1) exit 1}
  ' "$inspection" || { echo "Source patch count mismatch: $package" >&2; exit 1; }
  root_count=$(awk -F '\t' -v p="$package" -v v="$version" -v n="$nested_count" '
    NR>1 && $1==p && $2==v {if ($5!=n || $4<1) exit 1; print $4; count++}
    END {if (count!=1) exit 1}
  ' "$coverage") || { echo "License candidate coverage mismatch: $package" >&2; exit 1; }
  awk -F '\t' -v p="$package" -v v="$version" -v n="$root_count" '
    NR>1 && $1==p && $2==v {if ($7!="EXACT_TEXT_ALREADY_STAGED") exit 1; count++}
    END {if (count!=n) exit 1}
  ' "$roots" || { echo "Source-root license text not staged: $package" >&2; exit 1; }
  awk -F '\t' -v p="$package" -v v="$version" -v n="$nested_count" -v d="$nested_decision" '
    NR>1 && $1==p && $2==v {if ($5!=d) exit 1; count++}
    END {if (count!=n) exit 1}
  ' "$triage" || { echo "Nested license triage mismatch: $package" >&2; exit 1; }
  if [ "$name" = pcre2 ]; then
    awk -F '\t' -v p="$package" 'NR>1 && $1==p && $6=="EXACT_TEXT_STAGED" {count++} END {if (count!=1) exit 1}' \
      "$staged_runtime" || { echo "SLJIT license text not staged" >&2; exit 1; }
  fi
  recorded_count=$(awk -F '\t' -v p="$package" -v v="$version" '
    NR>1 && $1==p && $2==v && $4=="COLLECTED" {print $3; count++}
    END {if (count!=1) exit 1}
  ' "$license_manifest") || { echo "Missing license manifest entry: $package" >&2; exit 1; }
  actual_count=$(find "$e/licenses/$package" -type f | wc -l | tr -d '[:space:]')
  [ "$actual_count" = "$recorded_count" ] || { echo "License file count mismatch: $package" >&2; exit 1; }
  expected_dll_sha=$(awk -F '\t' -v p="$package" -v d="$dll" 'NR>1 && $1==d && $5==p {print $2; count++} END {if (count!=1) exit 1}' "$runtime") || {
    echo "Missing shipped DLL: $package" >&2; exit 1;
  }
  installed_dll_sha=$(sha256sum "/mingw64/bin/$dll"); installed_dll_sha=${installed_dll_sha%% *}
  [ "$installed_dll_sha" = "$expected_dll_sha" ] || { echo "DLL hash mismatch: $package" >&2; exit 1; }
  objdump -p "/mingw64/bin/$dll" > "$scratch/$name.imports"
  case "$name" in
    whisper.cpp) grep -Fq 'DLL Name: ggml.dll' "$scratch/$name.imports"; grep -Fq 'DLL Name: ggml-base.dll' "$scratch/$name.imports" ;;
    libtiff) grep -Fq 'DLL Name: libLerc.dll' "$scratch/$name.imports"; grep -Fq 'DLL Name: libdeflate.dll' "$scratch/$name.imports" ;;
    libvpl) grep -Fq 'DLL Name: libstdc++-6.dll' "$scratch/$name.imports" ;;
  esac
  member=$(tar tf "$archive" | grep '/PKGBUILD$' | head -n 1)
  [ -n "$member" ] || { echo "Missing PKGBUILD: $package" >&2; exit 1; }
  tar -xOf "$archive" "$member" > "$scratch/$name.PKGBUILD"
  if [ "$name" = pcre2 ]; then
    grep -Fq 'mv doc/${_realname}/COPYING licenses/${_realname}' "$scratch/$name.PKGBUILD" || {
      echo "PKGBUILD lacks PCRE2 license staging: $package" >&2; exit 1;
    }
  else
    grep -Fq 'share/licenses/' "$scratch/$name.PKGBUILD" || { echo "PKGBUILD lacks license staging: $package" >&2; exit 1; }
  fi
  case "$name" in
    pcre2) grep -Fq -- '--enable-jit' "$scratch/$name.PKGBUILD" ;;
    whisper.cpp) grep -Fq -- '-DWHISPER_USE_SYSTEM_GGML=ON' "$scratch/$name.PKGBUILD"; grep -Fq -- '-DWHISPER_BUILD_TESTS=OFF' "$scratch/$name.PKGBUILD" ;;
    libvpl) grep -Fq 'share/vpl/examples' "$scratch/$name.PKGBUILD" ;;
  esac
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tMSYS2_SOURCE_PACKAGE_VERIFIED\n' \
    "$package" "$version" "$url" "$expected_sha" "$source_kind" "$patch_count" "$root_count" "$nested_count" >> "$scratch/verification.tsv"
done

awk -F '\t' -v OFS='\t' '
  NR==FNR {if (NR>1) {key=$1 SUBSEP $2; url[key]=$3; sha[key]=$4} next}
  NR==1 {print; next}
  {key=$1 SUBSEP $2; if (key in url) {$5=url[key]; $6=sha[key]; $7="VERIFIED"; changed++} print}
  END {if (changed!=4) exit 1}
' "$scratch/verification.tsv" "$index" > "$scratch/source-index.tsv"
cp "$index" "$backup"
mv "$scratch/source-index.tsv" "$index"
mv "$scratch/verification.tsv" "$verification"
echo "Promoted four reviewed MSYS2 source-index rows; backup: $backup"
echo "Wrote: $verification"
