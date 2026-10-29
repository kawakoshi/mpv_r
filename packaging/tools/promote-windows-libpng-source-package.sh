#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
e=$1
p=mingw-w64-x86_64-libpng
v=1.6.58-1
url=https://repo.msys2.org/mingw/sources/mingw-w64-libpng-1.6.58-1.src.tar.zst
source_sha=9e985fc4cef509ec689f982dc6a948e9a8ee5184db25d65e9dd4c21872092348
patch_sha=a9c117324291cda7558ab36bec4ba28a34013d76e1ceaf9953749791a9e154a8
mozilla_commit=d014e15257f7cebaad4e4d45ffbd25b5959e6ecc
patch_dir="$e/libpng-apng-patch-provenance-v1"
archive="$e/source-packages/$p-$v.src.tar.zst"
index="$e/source-index.tsv"
backup="$e/source-index.pre-libpng-promotion.tsv"
verification="$e/libpng-source-verification-v1.tsv"
for required in "$archive" "$index" "$e/remaining-source-audit-summary-v1.tsv" \
  "$e/remaining-license-candidate-coverage-v1.tsv" "$e/remaining-root-license-staging-v2.tsv" \
  "$e/remaining-nested-license-build-triage-v4.tsv" "$e/license-manifest.tsv" \
  "$e/runtime-manifest.tsv" "$patch_dir/msys2-apng.patch" \
  "$patch_dir/mozilla-$mozilla_commit-apng.patch" "$patch_dir/mozilla-$mozilla_commit-moz.yaml"; do
  [ -f "$required" ] || { echo "Missing: $required" >&2; exit 1; }
done
for output in "$backup" "$verification"; do
  [ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 1; }
done

check_sha() {
  local actual
  actual=$(sha256sum "$1")
  [ "${actual%% *}" = "$2" ] || { echo "SHA mismatch: $1" >&2; exit 1; }
}
check_sha "$archive" "$source_sha"
check_sha "$patch_dir/msys2-apng.patch" "$patch_sha"
check_sha "$patch_dir/mozilla-$mozilla_commit-apng.patch" "$patch_sha"
grep -Eq '^[[:space:]]*license: libpng$' "$patch_dir/mozilla-$mozilla_commit-moz.yaml"
tar -xOf "$archive" mingw-w64-libpng/apng.patch | sha256sum | grep -Fq "$patch_sha"

awk -F '\t' -v p="$p" -v v="$v" -v u="$url" '
  NR>1 && $1==p && $2==v {if ($5!=u || $6!="MISSING" || $7!="PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION") exit 1; n++}
  END {if (n!=1) exit 1}
' "$index"
awk -F '\t' -v p="$p" -v v="$v" -v u="$url" -v h="$source_sha" '
  NR>1 && $1==p && $2==v {if ($3!="STANDARD_ARCHIVE" || $4!=u || $5!=h || $7!="UPSTREAM_SHA_MATCH") exit 1; n++}
  END {if (n!=1) exit 1}
' "$e/remaining-source-audit-summary-v1.tsv"
awk -F '\t' -v p="$p" -v v="$v" 'NR>1 && $1==p && $2==v {if ($4!=1 || $5!=3) exit 1; n++} END {if (n!=1) exit 1}' "$e/remaining-license-candidate-coverage-v1.tsv"
awk -F '\t' -v p="$p" -v v="$v" 'NR>1 && $1==p && $2==v {if ($7!="EXACT_TEXT_ALREADY_STAGED") exit 1; n++} END {if (n!=1) exit 1}' "$e/remaining-root-license-staging-v2.tsv"
awk -F '\t' -v p="$p" -v v="$v" 'NR>1 && $1==p && $2==v {if ($5!="OTHER_SOURCE_COMPONENT") exit 1; n++} END {if (n!=3) exit 1}' "$e/remaining-nested-license-build-triage-v4.tsv"
awk -F '\t' -v p="$p" -v v="$v" 'NR>1 && $1==p && $2==v {if ($3!=1 || $4!="COLLECTED") exit 1; n++} END {if (n!=1) exit 1}' "$e/license-manifest.tsv"
expected_dll_sha=$(awk -F '\t' -v p="$p" 'NR>1 && $1=="libpng16-16.dll" && $5==p {print $2; n++} END {if (n!=1) exit 1}' "$e/runtime-manifest.tsv")
check_sha /mingw64/bin/libpng16-16.dll "$expected_dll_sha"
scratch=$(mktemp -d "$e/.libpng-promotion.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
objdump -p /mingw64/bin/libpng16-16.dll > "$scratch/imports.txt"
grep -Fq 'DLL Name: zlib1.dll' "$scratch/imports.txt"
tar -xOf "$archive" mingw-w64-libpng/PKGBUILD > "$scratch/PKGBUILD"
grep -Fq "patch from https://bugzilla.mozilla.org/show_bug.cgi?id=2010431" "$scratch/PKGBUILD"
grep -Fq 'patch -p1 -i "${srcdir}/apng.patch"' "$scratch/PKGBUILD"
grep -Fq 'share/licenses/${_realname}/LICENSE' "$scratch/PKGBUILD"
grep -Fq 'contrib/pngminus' "$scratch/PKGBUILD"
test "$(find "$e/licenses/$p" -type f | wc -l | tr -d '[:space:]')" = 1

awk -F '\t' -v OFS='\t' -v p="$p" -v v="$v" -v u="$url" -v h="$source_sha" '
  NR==1 {print; next}
  $1==p && $2==v {$5=u; $6=h; $7="VERIFIED"; n++}
  {print}
  END {if (n!=1) exit 1}
' "$index" > "$scratch/source-index.tsv"
printf 'package\tversion\tsource_sha256\tmsys2_patch_sha256\tmatching_mozilla_commit\tlicense_record\tshipped_dll_sha256\tstatus\n%s\t%s\t%s\t%s\t%s\t%s\t%s\tVERIFIED\n' \
  "$p" "$v" "$source_sha" "$patch_sha" "$mozilla_commit" 'moz.yaml:origin.license=libpng' "$expected_dll_sha" > "$scratch/verification.tsv"
cp "$index" "$backup"
mv "$scratch/source-index.tsv" "$index"
mv "$scratch/verification.tsv" "$verification"
echo "Promoted libpng source index row; backup: $backup"
