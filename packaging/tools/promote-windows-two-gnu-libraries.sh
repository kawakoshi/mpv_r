#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
e=$1
index="$e/source-index.tsv"
backup="$e/source-index.pre-two-gnu-libraries.tsv"
verification="$e/two-gnu-libraries-verification-v1.tsv"
for f in "$index" "$e/remaining-source-audit-summary-v1.tsv" \
  "$e/msys2-source-package-inspection.tsv" "$e/remaining-license-candidate-coverage-v1.tsv" \
  "$e/remaining-root-license-staging-v2.tsv" "$e/license-manifest.tsv" "$e/runtime-manifest.tsv"; do
  [ -f "$f" ] || { echo "Missing: $f" >&2; exit 1; }
done
for f in "$backup" "$verification"; do
  [ ! -e "$f" ] || { echo "Refusing to overwrite: $f" >&2; exit 1; }
done
tmp=$(mktemp -d "$e/.two-gnu-libraries.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
printf 'package\tversion\tsource_url\tsource_sha256\tshipped_dll\tshipped_dll_sha256\troot_texts\tstatus\n' > "$tmp/verification.tsv"

for name in libtasn1 libunistring; do
  p=mingw-w64-x86_64-$name
  case "$name" in
    libtasn1) dll=libtasn1-6.dll; installed_text_a=COPYING; installed_text_b=COPYING.LESSERv2 ;;
    libunistring) dll=libunistring-5.dll; installed_text_a=LICENSE; installed_text_b=LICENSE.LIB ;;
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
  awk -F '\t' -v p="$p" -v v="$v" '
    NR>1 && $1==p && $2==v {if ($4!=2 || $5!=0) exit 1; n++}
    END {if (n!=1) exit 1}
  ' "$e/remaining-license-candidate-coverage-v1.tsv"
  awk -F '\t' -v p="$p" -v v="$v" '
    NR>1 && $1==p && $2==v {if ($7!="EXACT_TEXT_ALREADY_STAGED") exit 1; n++}
    END {if (n!=2) exit 1}
  ' "$e/remaining-root-license-staging-v2.tsv"
  awk -F '\t' -v p="$p" -v v="$v" '
    NR>1 && $1==p && $2==v {if ($3!=2 || $4!="COLLECTED") exit 1; n++}
    END {if (n!=1) exit 1}
  ' "$e/license-manifest.tsv"
  test "$(find "$e/licenses/$p" -type f | wc -l | tr -d '[:space:]')" = 2
  find "$e/licenses/$p" -name "$installed_text_a" | grep -q .
  find "$e/licenses/$p" -name "$installed_text_b" | grep -q .
  expected_dll_sha=$(awk -F '\t' -v p="$p" -v d="$dll" '
    NR>1 && $1==d && $5==p {print $2; n++}
    END {if (n!=1) exit 1}
  ' "$e/runtime-manifest.tsv")
  actual=$(sha256sum "/mingw64/bin/$dll"); [ "${actual%% *}" = "$expected_dll_sha" ] || exit 1
  objdump -p "/mingw64/bin/$dll" > "$tmp/$name.imports"
  case "$name" in
    libtasn1) ! grep -Eq 'DLL Name: (libunistring|libiconv)' "$tmp/$name.imports" ;;
    libunistring) grep -Fq 'DLL Name: libiconv-2.dll' "$tmp/$name.imports" ;;
  esac
  member=$(tar tf "$archive" | grep '/PKGBUILD$' | head -n1)
  tar -xOf "$archive" "$member" > "$tmp/$name.PKGBUILD"
  grep -Fq 'share/licenses/' "$tmp/$name.PKGBUILD"
  case "$name" in
    libtasn1) grep -Fq -- '--enable-shared' "$tmp/$name.PKGBUILD"; grep -Fq 'COPYING.LESSERv2' "$tmp/$name.PKGBUILD" ;;
    libunistring) grep -Fq -- '--disable-static' "$tmp/$name.PKGBUILD"; grep -Fq 'COPYING.LIB' "$tmp/$name.PKGBUILD" ;;
  esac
  printf '%s\t%s\t%s\t%s\t%s\t%s\t2\tVERIFIED\n' \
    "$p" "$v" "$url" "$source_sha" "$dll" "$expected_dll_sha" >> "$tmp/verification.tsv"
done

awk -F '\t' -v OFS='\t' '
  NR==FNR {if (NR>1) {key=$1 SUBSEP $2; url[key]=$3; sha[key]=$4} next}
  NR==1 {print; next}
  {key=$1 SUBSEP $2; if (key in url) {$5=url[key]; $6=sha[key]; $7="VERIFIED"; n++} print}
  END {if (n!=2) exit 1}
' "$tmp/verification.tsv" "$index" > "$tmp/source-index.tsv"
cp "$index" "$backup"
mv "$tmp/source-index.tsv" "$index"
mv "$tmp/verification.tsv" "$verification"
echo "Promoted libtasn1 and libunistring; backup retained."
