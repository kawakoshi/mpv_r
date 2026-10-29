#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi

e=$1
p=mingw-w64-x86_64-speex
v=1.2.1-1
dll=libspeex-1.dll
url=https://repo.msys2.org/mingw/sources/mingw-w64-speex-1.2.1-1.src.tar.zst
source_sha=e1a419b525ee19d808c47fce97890a4cae610627c5a74e533a1c322d596f11ef
license_sha=2654a4264b2bfe298dedc508748d140111840c315cc8eb646a3a68c13fa75b01
configure_sha=eab828c8c97f549c75c5e6ac81796c476cff8fbc12c493c0d80d0aeb73529fc7
makefile_sha=d1a9fda0fd926c816ac6a6481bab58be529951ebfde3ef4ecccf966236454c4c
index="$e/source-index.tsv"
archive="$e/source-packages/$p-$v.src.tar.zst"
backup="$e/source-index.pre-speex-promotion.tsv"
verification="$e/speex-source-verification-v1.tsv"

for f in "$index" "$archive" "$e/remaining-source-audit-summary-v1.tsv" \
  "$e/msys2-source-package-inspection.tsv" "$e/remaining-license-candidate-coverage-v1.tsv" \
  "$e/remaining-root-license-staging-v2.tsv" "$e/license-manifest.tsv" "$e/runtime-manifest.tsv"; do
  [ -f "$f" ] || { echo "Missing: $f" >&2; exit 1; }
done
for f in "$backup" "$verification"; do
  [ ! -e "$f" ] || { echo "Refusing to overwrite: $f" >&2; exit 1; }
done

check_sha() {
  local actual
  actual=$(sha256sum "$1")
  [ "${actual%% *}" = "$2" ] || { echo "SHA mismatch: $1" >&2; exit 1; }
}
check_sha "$archive" "$source_sha"

awk -F '\t' -v p="$p" -v v="$v" -v u="$url" '
  NR>1 && $1==p && $2==v {if ($5!=u || $6!="MISSING" || $7!="PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION") exit 1; n++}
  END {if (n!=1) exit 1}
' "$index"
awk -F '\t' -v p="$p" -v v="$v" -v u="$url" -v h="$source_sha" '
  NR>1 && $1==p && $2==v {if ($3!="STANDARD_ARCHIVE" || $4!=u || $5!=h || $7!="UPSTREAM_SHA_MATCH") exit 1; n++}
  END {if (n!=1) exit 1}
' "$e/remaining-source-audit-summary-v1.tsv"
awk -F '\t' -v p="$p" -v v="$v" -v h="$source_sha" '
  NR>1 && $1==p && $2==v {if ($3!=h || $5!=0) exit 1; n++}
  END {if (n!=1) exit 1}
' "$e/msys2-source-package-inspection.tsv"
awk -F '\t' -v p="$p" -v v="$v" '
  NR>1 && $1==p && $2==v {if ($4!=1 || $5!=0) exit 1; n++}
  END {if (n!=1) exit 1}
' "$e/remaining-license-candidate-coverage-v1.tsv"
awk -F '\t' -v p="$p" -v v="$v" -v h="$license_sha" '
  NR>1 && $1==p && $2==v {if ($5!=h || $7!="EXACT_TEXT_ALREADY_STAGED") exit 1; n++}
  END {if (n!=1) exit 1}
' "$e/remaining-root-license-staging-v2.tsv"
awk -F '\t' -v p="$p" -v v="$v" '
  NR>1 && $1==p && $2==v {if ($3!=1 || $4!="COLLECTED") exit 1; n++}
  END {if (n!=1) exit 1}
' "$e/license-manifest.tsv"
test "$(find "$e/licenses/$p" -type f | wc -l | tr -d '[:space:]')" = 1
license_file=$(find "$e/licenses/$p" -type f -name LICENSE)
[ -n "$license_file" ]
check_sha "$license_file" "$license_sha"

tmp=$(mktemp -d "$e/.speex-promotion.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
pkgbuild_member=$(tar tf "$archive" | grep '/PKGBUILD$' | head -n1)
source_member=$(tar tf "$archive" | grep 'speex-Speex-1.2.1.tar.gz$' | head -n1)
[ -n "$pkgbuild_member" ] && [ -n "$source_member" ]
tar -xOf "$archive" "$pkgbuild_member" > "$tmp/PKGBUILD"
tar -xOf "$archive" "$source_member" > "$tmp/source.tar.gz"
tar -xzOf "$tmp/source.tar.gz" speex-Speex-1.2.1/COPYING > "$tmp/COPYING"
tar -xzOf "$tmp/source.tar.gz" speex-Speex-1.2.1/configure.ac > "$tmp/configure.ac"
tar -xzOf "$tmp/source.tar.gz" speex-Speex-1.2.1/libspeex/Makefile.am > "$tmp/Makefile.am"
check_sha "$tmp/COPYING" "$license_sha"
check_sha "$tmp/configure.ac" "$configure_sha"
check_sha "$tmp/Makefile.am" "$makefile_sha"

grep -Fq 'install -Dm644 ${srcdir}/${_realname}-${pkgver}/COPYING' "$tmp/PKGBUILD"
grep -Fq -- '--enable-shared' "$tmp/PKGBUILD"
! grep -Fq -- '--enable-vorbis-psy' "$tmp/PKGBUILD"
! grep -Fq -- '--with-fft=' "$tmp/PKGBUILD"
grep -Fq 'AM_CONDITIONAL(BUILD_VORBIS_PSY' "$tmp/configure.ac"
grep -Fq 'if BUILD_VORBIS_PSY' "$tmp/Makefile.am"
grep -Fq 'libspeex_la_LIBADD = $(LIBM)' "$tmp/Makefile.am"
grep -Fq 'libspeex_la_SOURCES' "$tmp/Makefile.am"

expected_dll_sha=$(awk -F '\t' -v p="$p" -v d="$dll" '
  NR>1 && $1==d && $5==p {print $2; n++}
  END {if (n!=1) exit 1}
' "$e/runtime-manifest.tsv")
check_sha "/mingw64/bin/$dll" "$expected_dll_sha"
objdump -p "/mingw64/bin/$dll" > "$tmp/imports.txt"
! grep -Eq 'DLL Name: (libogg|libspeexdsp)' "$tmp/imports.txt"
nm -g "/mingw64/bin/$dll" > "$tmp/symbols.txt"
! grep -Ei 'vorbis_psy|kiss_fft|smallft|speexdsp|ogg_' "$tmp/symbols.txt"

awk -F '\t' -v OFS='\t' -v p="$p" -v v="$v" -v u="$url" -v h="$source_sha" '
  NR==1 {print; next}
  $1==p && $2==v {$5=u; $6=h; $7="VERIFIED"; n++}
  {print}
  END {if (n!=1) exit 1}
' "$index" > "$tmp/source-index.tsv"
printf 'package\tversion\tsource_sha256\tlicense_sha256\tconfigure_sha256\tlibspeex_makefile_sha256\tshipped_dll\tshipped_dll_sha256\tconditional_code_review\tstatus\n%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tVERIFIED\n' \
  "$p" "$v" "$source_sha" "$license_sha" "$configure_sha" "$makefile_sha" "$dll" "$expected_dll_sha" \
  'VORBIS_PSY_DISABLED_NO_EXTERNAL_DLL_IMPORTS_OR_MATCHING_SYMBOLS' > "$tmp/verification.tsv"
cp "$index" "$backup"
mv "$tmp/source-index.tsv" "$index"
mv "$tmp/verification.tsv" "$verification"
echo "Promoted Speex source index row; backup retained."
