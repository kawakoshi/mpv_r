#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 1 ]; then echo "Usage: $0 windows-evidence-dir" >&2; exit 2; fi
e=$1; index="$e/source-index.tsv"; backup="$e/source-index.pre-two-nested-seven.tsv"; verification="$e/two-nested-seven-verification-v1.tsv"
for f in "$index" "$e/runtime-manifest.tsv" "$e/license-manifest.tsv" "$e/remaining-source-audit-summary-v1.tsv" "$e/msys2-source-package-inspection.tsv" "$e/remaining-license-candidate-coverage-v1.tsv" "$e/remaining-root-license-staging-v2.tsv" "$e/remaining-nested-license-build-triage-v4.tsv";do [ -f "$f" ]||{ echo "Missing: $f" >&2;exit 1;};done
for f in "$backup" "$verification";do [ ! -e "$f" ]||{ echo "Refusing to overwrite: $f" >&2;exit 1;};done
scratch=$(mktemp -d "$e/.two-nested-seven.XXXXXX");trap 'rm -rf "$scratch"' EXIT
cat >"$scratch/packages.tsv" <<'ROWS'
package	version	source_kind	source_sha256	patch_count	patch_set_sha256	root_count	nested_set_sha256	license_count	classification
mingw-w64-x86_64-graphite2	1.3.15-1	SPECIAL_ARCHIVE	eb76ce274c68ea6bad0883144c21e44a803ec94fed9dc0f6584feb0a8415a1d6	5	cce25ec4fede174f48631c1a9846b8f108e6ab358f2d757db5fc1f674702cd05	2	1cdb31e4477ca928ea3cdfec51358e5bc59ecb943e34154f79f533f12b619183	2	DEBIAN_METADATA_AND_WEBSITE_TEXT_NOT_RUNTIME
mingw-w64-x86_64-libbluray	1.4.1-1	STANDARD_ARCHIVE	b67b1f41330c3fd52069540f0d9cb8c82ba04f18b711ffbfebcf47a68e378022	0	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855	1	1eccb4c3314dcd946b4ff8b6caba26c0f310c198768eee4020b5de87dc21d185	2	LIBUDFREAD_TEXT_STAGED_ASM_EXCLUDED_WITH_BDJ_DISABLED
mingw-w64-x86_64-libjpeg-turbo	3.1.4.1-3	STANDARD_ARCHIVE	5bd1e06caedda4d58adf9e28a4f08485b0a556b3263a2be73f7f800aa318419b	2	449e97651b67e84f02f46eabd1832e5f6c2e64490cf7962b6403b67ceca0de09	1	60e3cffdf4132b7004e40ea844f45609258263ff1904316df91410ff0db6e3b4	4	JAVA_AND_RELEASE_PACKAGING_TEXTS_NOT_RUNTIME
mingw-w64-x86_64-openssl	3.6.3-1	STANDARD_ARCHIVE	b8e8625cf89996d32c3d6c4db8a98c46de6558f5a4e7e98ae1287ec2d6a97e51	2	7b20ed43edf42e8f52c7f32a2582d00229ccacf30d5930d4c83ea808fb1f26c4	1	b9f4d93851af944422039e572a3f37969ebeefd73895bf1f64c05eba2205683a	2	PERL_BUILD_HELPERS_EXCLUDED_PATHTOOLS_CC0_STAGED
mingw-w64-x86_64-pango	1.57.1-1	STANDARD_ARCHIVE	5b6f46eec7e3abeda1c9e817d0a8cba6a9908a467f2d8fb33e86f4a24d8602d1	0	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855	1	0a0364c5962820e64183d734232359987518916436ee377863d8a2ef08483ac2	1	SYSTEM_FONTCONFIG_AND_GPERF_USED_NOT_FALLBACK_SUBPROJECTS
mingw-w64-x86_64-shaderc	2026.2-1	STANDARD_ARCHIVE	63f8080f99815cdab0ef3d77d724afbf21f8957ce5bd3d287a21527dc0a211b5	1	f9b5baa9c426fa9897254801dfa0c67f5cfe8bd35d179bb794eb206054bda806	1	686db91b27b851d8ac6a6ce2c35f2d5e1236ac44bd5f3fd621f332a0af0fa704	4	VENDORED_DIR_REMOVED_STATIC_BUILD_DEPENDENCY_LICENSES_STAGED
mingw-w64-x86_64-svt-av1	4.1.0-1	STANDARD_ARCHIVE	782da694549933d117a37743f14066be568765304b28ee529cffab86864e50c6	0	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855	1	7ecb827640eff90a1fbbf2ff9c172f98f274f41dec0269f0dbebbdbeb7daa2c3	3	FASTFEAT_TEXT_STAGED_SAFESTRING_APP_ONLY
ROWS
check_sha(){ local h;h=$(sha256sum "$1");h=${h%% *};[ "$h" = "$2" ]||{ echo "SHA mismatch: $1" >&2;exit 1;};}
printf 'package\tversion\tsource_sha256\tpatch_set_sha256\tnested_set_sha256\tclassification\truntime_files\tlicense_count\tstatus\n'>"$scratch/report"
while IFS=$'\t' read -r p v kind ssha pc psha roots nsha lc class;do
 [ "$p" = package ]&&continue;a="$e/source-packages/$p-$v.src.tar.zst";check_sha "$a" "$ssha"
 url=$(awk -F '\t' -v p="$p" -v v="$v" -v k="$kind" -v h="$ssha" 'NR>1&&$1==p&&$2==v{if($3!=k||$5!=h||$7!="UPSTREAM_SHA_MATCH"||$8!="LICENSE_REVIEW_PENDING")exit 1;print $4;n++}END{if(n!=1)exit 1}' "$e/remaining-source-audit-summary-v1.tsv")
 awk -F '\t' -v p="$p" -v v="$v" -v u="$url" 'NR>1&&$1==p&&$2==v{if($5!=u||$6!="MISSING"||$7!="PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION")exit 1;n++}END{if(n!=1)exit 1}' "$index"
 awk -F '\t' -v p="$p" -v v="$v" -v c="$pc" 'NR>1&&$1==p&&$2==v{if($5!=c)exit 1;n++}END{if(n!=1)exit 1}' "$e/msys2-source-package-inspection.tsv"
 awk -F '\t' -v p="$p" -v v="$v" -v r="$roots" 'NR>1&&$1==p&&$2==v{if($4!=r||$5!=2)exit 1;n++}END{if(n!=1)exit 1}' "$e/remaining-license-candidate-coverage-v1.tsv"
 d="$scratch/$p";mkdir -p "$d";tar xf "$a" -C "$d";root=$(find "$d" -mindepth 1 -maxdepth 1 -type d|head -n1);:>"$d/p";for f in "$root"/*.patch;do [ -f "$f" ]||continue;h=$(sha256sum "$f");printf '%s\t%s\n' "$(basename "$f")" "${h%% *}" >>"$d/p";done;sort -o "$d/p" "$d/p";[ "$(wc -l<"$d/p"|tr -d '[:space:]')" = "$pc" ];check_sha "$d/p" "$psha"
 awk -F '\t' -v p="$p" 'NR>1&&$1==p&&$5=="BUILD_COMPONENT_REVIEW_PENDING"{print $3"\t"$4}' "$e/remaining-nested-license-build-triage-v4.tsv"|sort>"$d/n";[ "$(wc -l<"$d/n"|tr -d '[:space:]')" = 2 ];check_sha "$d/n" "$nsha"
 case "$p" in *libbluray)check_sha "$e/licenses/$p/share/licenses/libbluray/libudfread/COPYING" dc626520dcd53a22f727af3ee42c770e56c97a64fe3adb063799d8ab032fe551;grep -Fq -- '-Dbdj_jar=disabled' "$root/PKGBUILD";;*openssl)check_sha "$e/licenses/$p/share/licenses/openssl/PATHTOOLS-CC0-NOTICE.txt" 97122849dcb43bd9f9b9eb38f4dff2f7fd610f974758c6f597e5e211af08c965;;*shaderc)grep -Fq "sed '/examples/d;/third_party/d'" "$root/PKGBUILD";[ -d "$e/licenses/$p/static-build-dependencies" ];;*svt-av1)check_sha "$e/licenses/$p/share/licenses/svt-av1/third_party/fastfeat/LICENSE" 043dcfd059386f9facd376351b2bd79325778744aa442177390cdfcca54babed;;esac
 recorded=$(awk -F '\t' -v p="$p" -v v="$v" 'NR>1&&$1==p&&$2==v{if($4!="COLLECTED")exit 1;print $3;n++}END{if(n!=1)exit 1}' "$e/license-manifest.tsv");actual=$(find "$e/licenses/$p" -type f|wc -l|tr -d '[:space:]');[ "$recorded" = "$lc" ];[ "$actual" = "$lc" ]
 files=;while IFS=$'\t' read -r dll h;do check_sha "/mingw64/bin/$dll" "$h";files="${files}${files:+,}$dll";done < <(awk -F '\t' -v p="$p" 'NR>1&&$5==p{print $1"\t"$2}' "$e/runtime-manifest.tsv"|sort);[ -n "$files" ]
 printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tVERIFIED\n' "$p" "$v" "$ssha" "$psha" "$nsha" "$class" "$files" "$lc">>"$scratch/report"
done<"$scratch/packages.tsv"
awk -F '\t' -v OFS='\t' 'NR==FNR{if(FNR>1)p[$1 SUBSEP $2]=$4;next}FNR==1{print;next}(($1 SUBSEP $2)in p){$6=p[$1 SUBSEP $2];$7="VERIFIED";n++}{print}END{if(n!=7)exit 1}' "$scratch/packages.tsv" "$index">"$scratch/index"
cp "$index" "$backup";mv "$scratch/index" "$index";mv "$scratch/report" "$verification";echo "Promoted seven packages after resolving two nested texts each."
