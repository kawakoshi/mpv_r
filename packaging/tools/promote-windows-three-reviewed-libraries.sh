#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
e=$1
index="$e/source-index.tsv"
triage="$e/remaining-nested-license-build-triage-v4.tsv"
backup_index="$e/source-index.pre-three-reviewed-libraries.tsv"
backup_triage="$e/remaining-nested-license-build-triage-v4.pre-three-reviewed-libraries.tsv"
verification="$e/three-reviewed-libraries-verification-v1.tsv"
for f in "$index" "$triage" "$e/remaining-source-audit-summary-v1.tsv" \
  "$e/msys2-source-package-inspection.tsv" "$e/remaining-license-candidate-coverage-v1.tsv" \
  "$e/remaining-root-license-staging-v2.tsv" "$e/license-manifest.tsv" "$e/runtime-manifest.tsv"; do
  [ -f "$f" ] || { echo "Missing: $f" >&2; exit 1; }
done
for f in "$backup_index" "$backup_triage" "$verification"; do
  [ ! -e "$f" ] || { echo "Refusing to overwrite: $f" >&2; exit 1; }
done
tmp=$(mktemp -d "$e/.three-reviewed-libraries.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
printf 'package\tversion\tsource_url\tsource_sha256\tshipped_dll\tshipped_dll_sha256\tnested_review\tstatus\n' > "$tmp/verification.tsv"

for name in spirv-cross liblc3 highway; do
  p=mingw-w64-x86_64-$name
  case "$name" in
    spirv-cross) dll=libspirv-cross-c-shared.dll; nested=0; nested_review=NONE ;;
    liblc3) dll=liblc3-1.dll; nested=1; nested_review=DUPLICATE_ROOT_TEXT_SOURCE_ONLY_PYTHON ;;
    highway) dll=libhwy.dll; nested=1; nested_review=DISTRIBUTION_METADATA_COVERED_BY_ROOT_LICENSE ;;
  esac
  record=$(awk -F '\t' -v p="$p" '
    NR>1 && $1==p && $3=="STANDARD_ARCHIVE" && $7=="UPSTREAM_SHA_MATCH" {print $2 "\t" $4 "\t" $5; n++}
    END {if (n!=1) exit 1}
  ' "$e/remaining-source-audit-summary-v1.tsv")
  v=${record%%$'\t'*}; rest=${record#*$'\t'}
  url=${rest%%$'\t'*}; source_sha=${rest#*$'\t'}
  archive="$e/source-packages/$p-$v.src.tar.zst"
  [ -f "$archive" ] || { echo "Missing archive: $p" >&2; exit 1; }
  actual=$(sha256sum "$archive"); [ "${actual%% *}" = "$source_sha" ] || exit 1
  awk -F '\t' -v p="$p" -v v="$v" -v u="$url" '
    NR>1 && $1==p && $2==v {if ($5!=u || $6!="MISSING" || $7!="PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION") exit 1; n++}
    END {if (n!=1) exit 1}
  ' "$index"
  awk -F '\t' -v p="$p" -v v="$v" -v h="$source_sha" '
    NR>1 && $1==p && $2==v {if ($3!=h || $5!=0) exit 1; n++}
    END {if (n!=1) exit 1}
  ' "$e/msys2-source-package-inspection.tsv"
  awk -F '\t' -v p="$p" -v v="$v" -v n="$nested" '
    NR>1 && $1==p && $2==v {if ($4!=1 || $5!=n) exit 1; count++}
    END {if (count!=1) exit 1}
  ' "$e/remaining-license-candidate-coverage-v1.tsv"
  awk -F '\t' -v p="$p" -v v="$v" '
    NR>1 && $1==p && $2==v {if ($7!="EXACT_TEXT_ALREADY_STAGED") exit 1; n++}
    END {if (n!=1) exit 1}
  ' "$e/remaining-root-license-staging-v2.tsv"
  awk -F '\t' -v p="$p" -v v="$v" '
    NR>1 && $1==p && $2==v {if ($3!=1 || $4!="COLLECTED") exit 1; n++}
    END {if (n!=1) exit 1}
  ' "$e/license-manifest.tsv"
  test "$(find "$e/licenses/$p" -type f | wc -l | tr -d '[:space:]')" = 1
  if [ "$nested" -eq 1 ]; then
    awk -F '\t' -v p="$p" -v v="$v" '
      NR>1 && $1==p && $2==v {if ($5!="BUILD_COMPONENT_REVIEW_PENDING") exit 1; n++}
      END {if (n!=1) exit 1}
    ' "$triage"
  fi
  expected_dll_sha=$(awk -F '\t' -v p="$p" -v d="$dll" '
    NR>1 && $1==d && $5==p {print $2; n++}
    END {if (n!=1) exit 1}
  ' "$e/runtime-manifest.tsv")
  actual=$(sha256sum "/mingw64/bin/$dll"); [ "${actual%% *}" = "$expected_dll_sha" ] || exit 1
  objdump -p "/mingw64/bin/$dll" > "$tmp/$name.imports"
  member=$(tar tf "$archive" | grep '/PKGBUILD$' | head -n1)
  tar -xOf "$archive" "$member" > "$tmp/$name.PKGBUILD"
  grep -Fq 'share/licenses/' "$tmp/$name.PKGBUILD"
  case "$name" in
    spirv-cross)
      grep -Fq -- '-DSPIRV_CROSS_SHARED=ON' "$tmp/$name.PKGBUILD"
      grep -Fq -- '-DSPIRV_CROSS_ENABLE_TESTS=OFF' "$tmp/$name.PKGBUILD"
      ! grep -Eq 'DLL Name: (glslang|SPIRV-Tools)' "$tmp/$name.imports"
      ;;
    liblc3)
      grep -Fq -- '--wrap-mode=nodownload' "$tmp/$name.PKGBUILD"
      grep -Fq -- '--default-library=shared' "$tmp/$name.PKGBUILD"
      root_sha=$(awk -F '\t' -v p="$p" '$1==p {print $5}' "$e/remaining-root-license-staging-v2.tsv")
      nested_sha=$(awk -F '\t' -v p="$p" '$1==p {print $4}' "$triage")
      [ "$root_sha" = "$nested_sha" ]
      ;;
    highway)
      grep -Fq -- '-DBUILD_TESTING=OFF' "$tmp/$name.PKGBUILD"
      f="$e/licenses/$p/share/licenses/highway/LICENSE"
      grep -Fq 'BSD 3-Clause License' "$f"
      grep -Fq 'CC0 1.0 Universal' "$f"
      grep -Fq 'Apache License 2.0' "$f"
      copyright="$e/highway-copyright-review-v1/debian-copyright.txt"
      [ -f "$copyright" ]
      expected_copyright_sha=$(awk -F '\t' -v p="$p" '$1==p {print $4; n++} END {if (n!=1) exit 1}' "$triage")
      actual_copyright_sha=$(sha256sum "$copyright"); [ "${actual_copyright_sha%% *}" = "$expected_copyright_sha" ]
      grep -Fq 'License: Apache-2.0' "$copyright"
      ;;
  esac
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\tVERIFIED\n' \
    "$p" "$v" "$url" "$source_sha" "$dll" "$expected_dll_sha" "$nested_review" >> "$tmp/verification.tsv"
done

awk -F '\t' -v OFS='\t' '
  NR==FNR {if (NR>1) {key=$1 SUBSEP $2; url[key]=$3; sha[key]=$4} next}
  NR==1 {print; next}
  {key=$1 SUBSEP $2; if (key in url) {$5=url[key]; $6=sha[key]; $7="VERIFIED"; n++} print}
  END {if (n!=3) exit 1}
' "$tmp/verification.tsv" "$index" > "$tmp/source-index.tsv"
awk -F '\t' -v OFS='\t' '
  NR==1 {print; next}
  $1=="mingw-w64-x86_64-liblc3" {$5="DUPLICATE_ROOT_TEXT_SOURCE_ONLY_PYTHON"; $6="python/LICENSE has the same SHA-256 as source root LICENSE; PKGBUILD ships shared C library."; n++}
  $1=="mingw-w64-x86_64-highway" {$5="DISTRIBUTION_METADATA_COVERED_BY_ROOT_LICENSE"; $6="debian/copyright restates Apache-2.0; staged root LICENSE also includes BSD-3-Clause and CC0-1.0 texts."; n++}
  {print}
  END {if (n!=2) exit 1}
' "$triage" > "$tmp/triage.tsv"
cp "$index" "$backup_index"
cp "$triage" "$backup_triage"
mv "$tmp/source-index.tsv" "$index"
mv "$tmp/triage.tsv" "$triage"
mv "$tmp/verification.tsv" "$verification"
echo "Promoted SPIRV-Cross, liblc3, and highway; backups retained."
