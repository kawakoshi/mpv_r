#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
e=$1
p=mingw-w64-x86_64-lcms2
v=2.19.1-1
dll=liblcms2-2.dll
url=https://repo.msys2.org/mingw/sources/mingw-w64-lcms2-2.19.1-1.src.tar.zst
source_sha=83414d0d95c5cb2548d3050670694e9efc64304a52190f42bcad951efa038b41
root_sha=6dbd60437f8ef91d8de1f08ad75882547fd4931bfcc3566a0735f28db1484d31
plugin_license_sha=c53a65c2fd561c87eaabf1072ef5dcab8653042bc15308465f52413585eb6271
index="$e/source-index.tsv"
triage="$e/remaining-nested-license-build-triage-v4.tsv"
archive="$e/source-packages/$p-$v.src.tar.zst"
backup_index="$e/source-index.pre-lcms2-promotion.tsv"
backup_triage="$e/remaining-nested-license-build-triage-v4.pre-lcms2-promotion.tsv"
verification="$e/lcms2-source-verification-v1.tsv"

for f in "$index" "$triage" "$archive" "$e/remaining-source-audit-summary-v1.tsv" \
  "$e/msys2-source-package-inspection.tsv" "$e/remaining-license-candidate-coverage-v1.tsv" \
  "$e/remaining-root-license-staging-v2.tsv" "$e/license-manifest.tsv" "$e/runtime-manifest.tsv"; do
  [ -f "$f" ] || { echo "Missing: $f" >&2; exit 1; }
done
for f in "$backup_index" "$backup_triage" "$verification"; do
  [ ! -e "$f" ] || { echo "Refusing to overwrite: $f" >&2; exit 1; }
done
check_sha() { local a; a=$(sha256sum "$1"); [ "${a%% *}" = "$2" ] || exit 1; }
check_sha "$archive" "$source_sha"

awk -F '\t' -v p="$p" -v v="$v" -v u="$url" 'NR>1&&$1==p&&$2==v {if($5!=u||$6!="MISSING"||$7!="PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION")exit 1;n++} END{if(n!=1)exit 1}' "$index"
awk -F '\t' -v p="$p" -v v="$v" -v u="$url" -v h="$source_sha" 'NR>1&&$1==p&&$2==v {if($3!="STANDARD_ARCHIVE"||$4!=u||$5!=h||$7!="UPSTREAM_SHA_MATCH")exit 1;n++} END{if(n!=1)exit 1}' "$e/remaining-source-audit-summary-v1.tsv"
awk -F '\t' -v p="$p" -v v="$v" -v h="$source_sha" 'NR>1&&$1==p&&$2==v {if($3!=h||$5!=0)exit 1;n++} END{if(n!=1)exit 1}' "$e/msys2-source-package-inspection.tsv"
awk -F '\t' -v p="$p" -v v="$v" 'NR>1&&$1==p&&$2==v {if($4!=1||$5!=2)exit 1;n++} END{if(n!=1)exit 1}' "$e/remaining-license-candidate-coverage-v1.tsv"
awk -F '\t' -v p="$p" -v v="$v" -v h="$root_sha" 'NR>1&&$1==p&&$2==v {if($5!=h||$7!="EXACT_TEXT_ALREADY_STAGED")exit 1;n++} END{if(n!=1)exit 1}' "$e/remaining-root-license-staging-v2.tsv"
awk -F '\t' -v p="$p" -v v="$v" -v h="$plugin_license_sha" 'NR>1&&$1==p&&$2==v {if($4!=h||$5!="BUILD_COMPONENT_REVIEW_PENDING")exit 1;n++} END{if(n!=2)exit 1}' "$triage"
awk -F '\t' -v p="$p" -v v="$v" 'NR>1&&$1==p&&$2==v {if($3!=2||$4!="COLLECTED")exit 1;n++} END{if(n!=1)exit 1}' "$e/license-manifest.tsv"
test "$(find "$e/licenses/$p" -type f | wc -l | tr -d '[:space:]')" = 2
check_sha "$e/licenses/$p/share/licenses/lcms2/LICENSE" "$root_sha"
check_sha "$e/licenses/$p/share/licenses/lcms2/LICENSE-fast_float" "$plugin_license_sha"

tmp=$(mktemp -d "$e/.lcms2-promotion.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
pkgbuild_member=$(tar tf "$archive" | grep '/PKGBUILD$' | head -n1)
source_member=$(tar tf "$archive" | grep 'lcms2-2.19.1.tar.gz$' | head -n1)
tar -xOf "$archive" "$pkgbuild_member" > "$tmp/PKGBUILD"
tar -xOf "$archive" "$source_member" > "$tmp/source.tar.gz"
tar -xzOf "$tmp/source.tar.gz" lcms2-2.19.1/meson_options.txt > "$tmp/meson_options.txt"
tar -xzOf "$tmp/source.tar.gz" lcms2-2.19.1/plugins/meson.build > "$tmp/plugins-meson.build"
tar -xzOf "$tmp/source.tar.gz" lcms2-2.19.1/src/meson.build > "$tmp/src-meson.build"
grep -Fq "option('fastfloat', type: 'boolean', value: false" "$tmp/meson_options.txt"
grep -Fq "option('threaded', type: 'boolean', value: false" "$tmp/meson_options.txt"
grep -Fq "if get_option('fastfloat')" "$tmp/plugins-meson.build"
grep -Fq "if get_option('threaded')" "$tmp/plugins-meson.build"
grep -Fq "liblcms2_lib = library(" "$tmp/src-meson.build"
grep -Fq -- '-Dfastfloat=true' "$tmp/PKGBUILD"
! grep -Fq -- '-Dthreaded=true' "$tmp/PKGBUILD"
grep -Fq 'LICENSE-fast_float' "$tmp/PKGBUILD"

expected_dll_sha=$(awk -F '\t' -v p="$p" -v d="$dll" 'NR>1&&$1==d&&$5==p {print $2;n++} END{if(n!=1)exit 1}' "$e/runtime-manifest.tsv")
check_sha "/mingw64/bin/$dll" "$expected_dll_sha"
objdump -p "/mingw64/bin/$dll" > "$tmp/main.imports"
! grep -Fq 'liblcms2_fast_float' "$tmp/main.imports"
if awk -F '\t' '$1=="liblcms2_fast_float-2.dll" {found=1} END{exit !found}' "$e/runtime-manifest.tsv"; then
  echo "GPL fast-float plugin unexpectedly present in candidate runtime" >&2; exit 1
fi
[ -f /mingw64/bin/liblcms2_fast_float-2.dll ]
objdump -p /mingw64/bin/liblcms2_fast_float-2.dll > "$tmp/plugin.imports"
grep -Fq 'DLL Name: liblcms2-2.dll' "$tmp/plugin.imports"

awk -F '\t' -v OFS='\t' -v p="$p" -v v="$v" -v u="$url" -v h="$source_sha" 'NR==1{print;next}$1==p&&$2==v{$5=u;$6=h;$7="VERIFIED";n++}{print}END{if(n!=1)exit 1}' "$index" > "$tmp/index.tsv"
awk -F '\t' -v OFS='\t' -v p="$p" 'NR==1{print;next}$1==p{$5="SEPARATE_GPL_PLUGIN_NOT_SHIPPED";$6="GPL-3.0 fast-float and threaded sources build separate plugin DLLs; candidate runtime ships only liblcms2-2.dll. GPL text is staged.";n++}{print}END{if(n!=2)exit 1}' "$triage" > "$tmp/triage.tsv"
printf 'package\tversion\tsource_sha256\tmain_dll\tmain_dll_sha256\tplugin_license_sha256\tplugin_runtime_status\tstatus\n%s\t%s\t%s\t%s\t%s\t%s\t%s\tVERIFIED\n' "$p" "$v" "$source_sha" "$dll" "$expected_dll_sha" "$plugin_license_sha" 'SEPARATE_DLL_NOT_SHIPPED_TEXT_STAGED' > "$tmp/verification.tsv"
cp "$index" "$backup_index"
cp "$triage" "$backup_triage"
mv "$tmp/index.tsv" "$index"
mv "$tmp/triage.tsv" "$triage"
mv "$tmp/verification.tsv" "$verification"
echo "Promoted LittleCMS source index row; backups retained."
