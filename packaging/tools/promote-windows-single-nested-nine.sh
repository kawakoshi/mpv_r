#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then echo "Usage: $0 windows-evidence-dir" >&2; exit 2; fi
e=$1; index="$e/source-index.tsv"
backup="$e/source-index.pre-single-nested-nine.tsv"
verification="$e/single-nested-nine-verification-v1.tsv"
for required in "$index" "$e/runtime-manifest.tsv" "$e/license-manifest.tsv" "$e/remaining-source-audit-summary-v1.tsv" "$e/msys2-source-package-inspection.tsv" "$e/remaining-license-candidate-coverage-v1.tsv" "$e/remaining-root-license-staging-v2.tsv" "$e/remaining-nested-license-build-triage-v4.tsv"; do
  [ -f "$required" ] || { echo "Missing: $required" >&2; exit 1; }
done
for output in "$backup" "$verification"; do [ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 1; }; done
scratch=$(mktemp -d "$e/.single-nested-nine.XXXXXX"); trap 'rm -rf "$scratch"' EXIT

cat > "$scratch/packages.tsv" <<'ROWS'
package	version	source_kind	source_sha256	patch_count	patch_set_sha256	root_count	root_exact_count	nested_count	pending_sha256	license_count	classification
mingw-w64-x86_64-libdovi	3.3.2-1	STANDARD_ARCHIVE	6e5309f4ffc7b78b14ec6e9a68e9eb5e25be11162688e0f57d5496709529e5bb	0	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855	1	1	1	f35d4515dd8d81c7996af2b20e9605561d1af0c21bc12ba7cc4fa4c60aed2178	1	NESTED_TEXT_DUPLICATES_STAGED_ROOT
mingw-w64-x86_64-libgme	0.6.5-2	STANDARD_ARCHIVE	b77a9be1dd65255df797a793a525a25a73b75a8c3c1379f79b2ea9376e854fd6	0	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855	2	1	1	8fb093f26ed0d78c8ca033bbec7063ac5b34c5d2475e6bd121d03ccfaaf2355f	2	EMU2413_MIT_TEXT_STAGED
mingw-w64-x86_64-libiconv	1.19-1	STANDARD_ARCHIVE	74428280c17094da5b702c29b2e1a0abae59556ea5dfdd65705cc8ccc1e000fb	3	72b659a6dab86c9f671e73bf55baf886a7970dd5cd1b12d0f575cb57ed6ce559	2	2	1	20e50fe7aae3e56378ebf0417d9de904f55a0e61e4df315333e632a4d3555d95	4	LIBCHARSET_TEXT_ALREADY_STAGED
mingw-w64-x86_64-libplacebo	7.360.1-1	STANDARD_ARCHIVE	f77e526962fb70963d1451ed9f8137580236d58a411fa118efcf2aad8c632172	1	1bcbce67fa73a2f4f94b14e65e8377aa3099d34efd777f8a99a82787a4dcfefb	1	1	1	a2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499	1	DEMO_EXECUTABLE_TEXT_NOT_IN_PORTABLE_RUNTIME
mingw-w64-x86_64-libsoxr	0.1.3-5	PINNED_GIT	6473c8fe8f9f25bd9335cb00432c42e311ce134475f7baa1d741d0a3399c787a	2	1711c3ec651cd2c8152fafe200fb09e61aee574138701fa3ef83b02ac326516b	2	2	1	32b1062f7da84967e7019d01ab805935caa7ab7321a7ced0e30ebe75e5df1670	3	TEST_TEXT_EXCLUDED_BY_BUILD_TESTS_OFF
mingw-w64-x86_64-rav1e	0.8.1-1	STANDARD_ARCHIVE	4a991f3a7d0e4ef23bc5e7eaae9ea0c83d16a18c48a3e621f1f3dfb10464b49d	0	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855	1	1	1	5d3c397a3aeeecbc417962e4df8e8432af8219fda8a56ebe601a638a1e76c522	3	IVF_DEFAULT_FEATURE_TEXT_STAGED
mingw-w64-x86_64-zlib	1.3.2-2	STANDARD_ARCHIVE	eef69dea52357e01b272d6fd6dc4d7c0773f71260cb7bcde6047c8c383518db3	6	9ebc12dcd20170bd4b9ec536305fd613bc711900b7be5b791c4eb073b3694fd1	1	1	1	fc686023047ce5ce3a18a9b8a777156f0e475929d3de06bac279f3c025d2b2ca	1	MINIZIP_TEXT_BELONGS_TO_SEPARATE_PACKAGE
mingw-w64-x86_64-zstd	1.5.7-2	STANDARD_ARCHIVE	306797282df799e95d550e6d0bb4b0a7b848027b8e13893a24236e060837c217	1	8a590371e3f3cdb2619204b9fb996863da37082fc2cc7749a3859339386d5043	2	1	1	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855	1	NESTED_BUILD_LICENSE_IS_EMPTY
mingw-w64-x86_64-harfbuzz	14.2.1-1	STANDARD_ARCHIVE	1776f26fcb0a81b0fda74f4782df6f4c4632e167af9506e4adbf37d14dbbeead	2	2098936c6f2b860514acf98215f243f4459169ac85423910f5019d2a5e8c2eff	1	1	4	c2cfccb812fe482101a8f04597dfc5a9991a6b2748266c47ac91b6a5aae15383	2	MICROSOFT_USE_DATA_TEXT_STAGED_THREE_TEST_TEXTS_EXCLUDED
ROWS

check_sha(){ local h; h=$(sha256sum "$1"); h=${h%% *}; [ "$h" = "$2" ] || { echo "SHA-256 mismatch: $1" >&2; exit 1; }; }
printf 'package\tversion\tsource_sha256\tpatch_set_sha256\tpending_nested_sha256\tclassification\truntime_files\tlicense_count\tstatus\n' > "$scratch/verification.tsv"
while IFS=$'\t' read -r package version source_kind source_sha patch_count patch_set_sha root_count root_exact_count nested_count pending_sha license_count classification; do
  [ "$package" = package ] && continue
  archive="$e/source-packages/$package-$version.src.tar.zst"; check_sha "$archive" "$source_sha"
  upstream=UPSTREAM_SHA_MATCH; [ "$source_kind" = PINNED_GIT ] && upstream=PINNED_REF_PRESENT_NEEDS_LICENSE_REVIEW
  source_url=$(awk -F '\t' -v p="$package" -v v="$version" -v k="$source_kind" -v h="$source_sha" -v u="$upstream" 'NR>1&&$1==p&&$2==v{if($3!=k||$5!=h||$7!=u||$8!="LICENSE_REVIEW_PENDING")exit 1;print $4;n++}END{if(n!=1)exit 1}' "$e/remaining-source-audit-summary-v1.tsv")
  awk -F '\t' -v p="$package" -v v="$version" -v u="$source_url" 'NR>1&&$1==p&&$2==v{if($5!=u||$6!="MISSING"||$7!="PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION")exit 1;n++}END{if(n!=1)exit 1}' "$index"
  awk -F '\t' -v p="$package" -v v="$version" -v c="$patch_count" 'NR>1&&$1==p&&$2==v{if($5!=c)exit 1;n++}END{if(n!=1)exit 1}' "$e/msys2-source-package-inspection.tsv"
  awk -F '\t' -v p="$package" -v v="$version" -v r="$root_count" -v n="$nested_count" 'NR>1&&$1==p&&$2==v{if($4!=r||$5!=n)exit 1;c++}END{if(c!=1)exit 1}' "$e/remaining-license-candidate-coverage-v1.tsv"
  exact=$(awk -F '\t' -v p="$package" 'NR>1&&$1==p&&$7=="EXACT_TEXT_ALREADY_STAGED"{n++}END{print n+0}' "$e/remaining-root-license-staging-v2.tsv"); [ "$exact" = "$root_exact_count" ]
  awk -F '\t' -v p="$package" -v h="$pending_sha" 'NR>1&&$1==p&&$5=="BUILD_COMPONENT_REVIEW_PENDING"{if($4!=h)exit 1;n++}END{if(n!=1)exit 1}' "$e/remaining-nested-license-build-triage-v4.tsv"
  if [ "$package" = mingw-w64-x86_64-harfbuzz ]; then awk -F '\t' -v p="$package" 'NR>1&&$1==p&&$5=="SOURCE_ONLY_SAMPLE_OR_TEST"{n++}END{if(n!=3)exit 1}' "$e/remaining-nested-license-build-triage-v4.tsv"; fi
  d="$scratch/$package"; mkdir -p "$d"; tar xf "$archive" -C "$d"; root=$(find "$d" -mindepth 1 -maxdepth 1 -type d|head -n1); : > "$d/patches.tsv"
  for patch in "$root"/*.patch; do [ -f "$patch" ]||continue; h=$(sha256sum "$patch"); printf '%s\t%s\n' "$(basename "$patch")" "${h%% *}" >> "$d/patches.tsv"; done
  sort -o "$d/patches.tsv" "$d/patches.tsv"; [ "$(wc -l < "$d/patches.tsv"|tr -d '[:space:]')" = "$patch_count" ]; check_sha "$d/patches.tsv" "$patch_set_sha"
  case "$package" in
    *libgme) check_sha "$e/licenses/$package/share/licenses/libgme/ext/LICENSE" "$pending_sha" ;;
    *libiconv) check_sha "$e/licenses/$package/share/licenses/libiconv/libcharset/COPYING.LIB" "$pending_sha" ;;
    *libsoxr) grep -Fq -- '-DBUILD_TESTS=OFF' "$root/PKGBUILD" ;;
    *rav1e) check_sha "$e/licenses/$package/share/licenses/rav1e/ivf/LICENSE" "$pending_sha" ;;
    *zlib) grep -Fq 'package_minizip' "$root/PKGBUILD" ;;
    *zstd) [ "$pending_sha" = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 ] ;;
    *harfbuzz) check_sha "$e/licenses/$package/share/licenses/harfbuzz/ms-use/COPYING" "$pending_sha" ;;
  esac
  recorded=$(awk -F '\t' -v p="$package" -v v="$version" 'NR>1&&$1==p&&$2==v{if($4!="COLLECTED")exit 1;print $3;n++}END{if(n!=1)exit 1}' "$e/license-manifest.tsv"); actual=$(find "$e/licenses/$package" -type f|wc -l|tr -d '[:space:]'); [ "$recorded" = "$license_count" ]; [ "$actual" = "$license_count" ]
  runtime_files=
  while IFS=$'\t' read -r dll sha; do check_sha "/mingw64/bin/$dll" "$sha"; runtime_files="${runtime_files}${runtime_files:+,}$dll"; done < <(awk -F '\t' -v p="$package" 'NR>1&&$5==p{print $1"\t"$2}' "$e/runtime-manifest.tsv"|sort)
  [ -n "$runtime_files" ]
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tVERIFIED\n' "$package" "$version" "$source_sha" "$patch_set_sha" "$pending_sha" "$classification" "$runtime_files" "$license_count" >> "$scratch/verification.tsv"
done < "$scratch/packages.tsv"
awk -F '\t' -v OFS='\t' 'NR==FNR{if(FNR>1)p[$1 SUBSEP $2]=$4;next}FNR==1{print;next}(($1 SUBSEP $2)in p){$6=p[$1 SUBSEP $2];$7="VERIFIED";n++}{print}END{if(n!=9)exit 1}' "$scratch/packages.tsv" "$index" > "$scratch/index.tsv"
cp "$index" "$backup"; mv "$scratch/index.tsv" "$index"; mv "$scratch/verification.tsv" "$verification"
echo "Promoted nine packages after resolving their single nested runtime-license question."
