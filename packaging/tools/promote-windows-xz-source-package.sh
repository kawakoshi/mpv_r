#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
e=$1
p=mingw-w64-x86_64-xz
v=5.8.3-1
dll=liblzma-5.dll
url=https://repo.msys2.org/mingw/sources/mingw-w64-xz-5.8.3-1.src.tar.zst
source_sha=a6096b17f7144d3ec4a35f70ebdc0819df0f6ed331f53b04d2a4452d5b66ed55
index="$e/source-index.tsv"
archive="$e/source-packages/$p-$v.src.tar.zst"
backup="$e/source-index.pre-xz-promotion.tsv"
verification="$e/xz-source-verification-v1.tsv"
for f in "$index" "$archive" "$e/remaining-source-audit-summary-v1.tsv" "$e/msys2-source-package-inspection.tsv" \
  "$e/remaining-license-candidate-coverage-v1.tsv" "$e/remaining-root-license-staging-v2.tsv" \
  "$e/license-manifest.tsv" "$e/runtime-manifest.tsv"; do
  [ -f "$f" ] || { echo "Missing: $f" >&2; exit 1; }
done
for f in "$backup" "$verification"; do [ ! -e "$f" ] || { echo "Refusing to overwrite: $f" >&2; exit 1; }; done
check_sha() { local a; a=$(sha256sum "$1"); [ "${a%% *}" = "$2" ] || exit 1; }
check_sha "$archive" "$source_sha"
awk -F '\t' -v p="$p" -v v="$v" -v u="$url" 'NR>1&&$1==p&&$2==v{if($5!=u||$6!="MISSING"||$7!="PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION")exit 1;n++}END{if(n!=1)exit 1}' "$index"
awk -F '\t' -v p="$p" -v v="$v" -v u="$url" -v h="$source_sha" 'NR>1&&$1==p&&$2==v{if($3!="STANDARD_ARCHIVE"||$4!=u||$5!=h||$7!="UPSTREAM_SHA_MATCH")exit 1;n++}END{if(n!=1)exit 1}' "$e/remaining-source-audit-summary-v1.tsv"
awk -F '\t' -v p="$p" -v v="$v" -v h="$source_sha" 'NR>1&&$1==p&&$2==v{if($3!=h||$5!=0)exit 1;n++}END{if(n!=1)exit 1}' "$e/msys2-source-package-inspection.tsv"
awk -F '\t' -v p="$p" -v v="$v" 'NR>1&&$1==p&&$2==v{if($4!=5||$5!=0)exit 1;n++}END{if(n!=1)exit 1}' "$e/remaining-license-candidate-coverage-v1.tsv"
awk -F '\t' -v p="$p" -v v="$v" 'NR>1&&$1==p&&$2==v{if($7!="EXACT_TEXT_ALREADY_STAGED")exit 1;n++}END{if(n!=5)exit 1}' "$e/remaining-root-license-staging-v2.tsv"
awk -F '\t' -v p="$p" -v v="$v" 'NR>1&&$1==p&&$2==v{if($3!=5||$4!="COLLECTED")exit 1;n++}END{if(n!=1)exit 1}' "$e/license-manifest.tsv"
test "$(find "$e/licenses/$p" -type f | wc -l | tr -d '[:space:]')" = 5

tmp=$(mktemp -d "$e/.xz-promotion.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
pkgbuild_member=$(tar tf "$archive" | grep '/PKGBUILD$' | head -n1)
source_member=$(tar tf "$archive" | grep 'xz-5.8.3.tar.xz$' | head -n1)
tar -xOf "$archive" "$pkgbuild_member" > "$tmp/PKGBUILD"
tar -xOf "$archive" "$source_member" > "$tmp/source.tar.xz"
tar -xJOf "$tmp/source.tar.xz" xz-5.8.3/COPYING > "$tmp/COPYING"
grep -Fq 'liblzma is under the BSD Zero Clause License (0BSD)' "$tmp/COPYING"
grep -Fq "install -Dm644 \"\${srcdir}\"/\${_realname}-\${pkgver}/COPYING*" "$tmp/PKGBUILD"
grep -Fq -- '--disable-nls' "$tmp/PKGBUILD"
for name in COPYING COPYING.0BSD COPYING.GPLv2 COPYING.GPLv3 COPYING.LGPLv2.1; do
  source_text=$(tar -xJOf "$tmp/source.tar.xz" "xz-5.8.3/$name" | sha256sum); source_text=${source_text%% *}
  check_sha "$e/licenses/$p/share/licenses/xz/$name" "$source_text"
done
expected_dll_sha=$(awk -F '\t' -v p="$p" -v d="$dll" 'NR>1&&$1==d&&$5==p{print $2;n++}END{if(n!=1)exit 1}' "$e/runtime-manifest.tsv")
check_sha "/mingw64/bin/$dll" "$expected_dll_sha"
objdump -p "/mingw64/bin/$dll" > "$tmp/imports.txt"
! grep -Eq 'DLL Name: (libintl|libiconv)' "$tmp/imports.txt"
awk -F '\t' -v OFS='\t' -v p="$p" -v v="$v" -v u="$url" -v h="$source_sha" 'NR==1{print;next}$1==p&&$2==v{$5=u;$6=h;$7="VERIFIED";n++}{print}END{if(n!=1)exit 1}' "$index" > "$tmp/index.tsv"
printf 'package\tversion\tsource_sha256\tshipped_dll\tshipped_dll_sha256\tstaged_license_texts\tliblzma_license\tstatus\n%s\t%s\t%s\t%s\t%s\t5\t0BSD\tVERIFIED\n' "$p" "$v" "$source_sha" "$dll" "$expected_dll_sha" > "$tmp/verification.tsv"
cp "$index" "$backup"
mv "$tmp/index.tsv" "$index"
mv "$tmp/verification.tsv" "$verification"
echo "Promoted XZ source index row; backup retained."
