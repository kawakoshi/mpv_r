#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 1 ]; then echo "Usage: $0 windows-evidence-dir" >&2; exit 2; fi
export LC_ALL=C
e=$1; index="$e/source-index.tsv"; backup="$e/source-index.pre-final-three.tsv"; verification="$e/final-three-verification-v1.tsv"
for f in "$index" "$e/runtime-manifest.tsv" "$e/license-manifest.tsv" "$e/remaining-source-audit-summary-v1.tsv" "$e/msys2-source-package-inspection.tsv" "$e/remaining-license-candidate-coverage-v1.tsv" "$e/remaining-nested-license-build-triage-v4.tsv" "$e/final-runtime-notice-staging-v1.tsv" "$e/librsvg-symlink-license-correction-v1.tsv"; do [ -f "$f" ] || { echo "Missing: $f" >&2; exit 1; }; done
for f in "$backup" "$verification"; do [ ! -e "$f" ] || { echo "Refusing to overwrite: $f" >&2; exit 1; }; done
scratch=$(mktemp -d "$e/.final-three.XXXXXX"); trap 'rm -rf "$scratch"' EXIT
cat > "$scratch/packages.tsv" <<'ROWS'
package	version	source_kind	upstream_status	source_sha256	patch_count	patch_set_sha256	root_count	nested_count	nested_set_sha256	license_count	classification
mingw-w64-x86_64-librsvg	2.62.3-1	STANDARD_ARCHIVE	UPSTREAM_SHA_MATCH	6007e8f5960b63f2d71d6a8418bc414104c5c9998f741cd8f53e17a7cced41ac	1	affe9c24dcb9651beef10f3b89999fe1f5df3fcf16f608c8efccc16ba3177c93	1	8	3a0efc3dcacda295faf122b0761938f67583c93968432a970b4e0f2d18644426	1	SEVEN_SYMLINKS_CORRECTED_ROOT_LICENSE_STAGED_REBIND_NOT_RUNTIME
mingw-w64-x86_64-libwinpthread	14.0.0.r147.g31bd54ab7-1	PINNED_GIT	PINNED_REF_PRESENT_NEEDS_LICENSE_REVIEW	ceb7dee96c7074babae0052880b8cae815f2ddb29bdcdfb72018f2d2c53c3ce7	1	0bc86b0fe996147080659930b9ad256b761383edc2ad20a75d1788f4a29114c7	1	10	9ada11f7be8ad0e210bf445aca8483abe6397c96e9259be6141348ca37ffa260	2	WINPTHREAD_AND_MINGW_RUNTIME_NOTICES_STAGED_OTHER_TREE_COMPONENTS_EXCLUDED
mingw-w64-x86_64-gcc-libs	16.1.0-5	STANDARD_ARCHIVE	UPSTREAM_SHA_MATCH	947166ed372d28ab8ffa25a66bc5e37a60a42e96a686424ce58cad304fcaea15	13	1521a87798459d2bdba7fd52af67218f57c78cb01d5a1006834041d2c6076b17	3	26	9822457784ccf81e1cc5eff075f0b767622dc5a719c089c1ee3913b052e02ec4	4	GCC_RUNTIME_LICENSE_SET_STAGED_COMPILER_HEADERS_DOCS_AND_UNSHIPPED_LIBS_EXCLUDED
ROWS
check_sha(){ local h; h=$(sha256sum "$1"); h=${h%% *}; [ "$h" = "$2" ] || { echo "SHA mismatch: $1" >&2; exit 1; }; }
printf 'package\tversion\tsource_sha256\tpatch_set_sha256\tnested_set_sha256\tclassification\truntime_files\tlicense_count\tstatus\n' > "$scratch/report"
while IFS=$'\t' read -r p v kind upstream ssha pc psha roots nested nsha lc class; do
  [ "$p" = package ] && continue
  a="$e/source-packages/$p-$v.src.tar.zst"; check_sha "$a" "$ssha"
  url=$(awk -F '\t' -v p="$p" -v v="$v" -v k="$kind" -v u="$upstream" -v h="$ssha" 'NR>1&&$1==p&&$2==v{if($3!=k||$5!=h||$7!=u||$8!="LICENSE_REVIEW_PENDING")exit 1;print $4;n++}END{if(n!=1)exit 1}' "$e/remaining-source-audit-summary-v1.tsv")
  awk -F '\t' -v p="$p" -v v="$v" -v u="$url" 'NR>1&&$1==p&&$2==v{if($5!=u||$6!="MISSING"||$7!="PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION")exit 1;n++}END{if(n!=1)exit 1}' "$index"
  awk -F '\t' -v p="$p" -v v="$v" -v c="$pc" 'NR>1&&$1==p&&$2==v{if($5!=c)exit 1;n++}END{if(n!=1)exit 1}' "$e/msys2-source-package-inspection.tsv"
  awk -F '\t' -v p="$p" -v v="$v" -v r="$roots" -v n="$nested" 'NR>1&&$1==p&&$2==v{if($4!=r||$5!=n)exit 1;c++}END{if(c!=1)exit 1}' "$e/remaining-license-candidate-coverage-v1.tsv"
  d="$scratch/$p"; mkdir -p "$d"; tar xf "$a" -C "$d"; root=$(find "$d" -mindepth 1 -maxdepth 1 -type d | head -n1)
  : > "$d/patches"; for f in "$root"/*.patch; do [ -f "$f" ] || continue; h=$(sha256sum "$f"); printf '%s\t%s\n' "$(basename "$f")" "${h%% *}" >> "$d/patches"; done; sort -o "$d/patches" "$d/patches"; [ "$(wc -l < "$d/patches" | tr -d '[:space:]')" = "$pc" ]; check_sha "$d/patches" "$psha"
  awk -F '\t' -v p="$p" 'NR>1&&$1==p{print $3"\t"$4"\t"$5}' "$e/remaining-nested-license-build-triage-v4.tsv" | sort > "$d/nested"; [ "$(wc -l < "$d/nested" | tr -d '[:space:]')" = "$nested" ]; check_sha "$d/nested" "$nsha"
  recorded=$(awk -F '\t' -v p="$p" -v v="$v" 'NR>1&&$1==p&&$2==v{if($4!="COLLECTED")exit 1;print $3;n++}END{if(n!=1)exit 1}' "$e/license-manifest.tsv"); actual=$(find "$e/licenses/$p" -type f | wc -l | tr -d '[:space:]'); [ "$recorded" = "$lc" ]; [ "$actual" = "$lc" ]
  case "$p" in
    *librsvg) check_sha "$e/licenses/$p/share/licenses/librsvg/COPYING.LIB" dc626520dcd53a22f727af3ee42c770e56c97a64fe3adb063799d8ab032fe551; [ "$(awk 'END{print NR}' "$e/librsvg-symlink-license-correction-v1.tsv")" = 8 ] ;;
    *libwinpthread) check_sha "$e/licenses/$p/share/licenses/libwinpthread/COPYING" 63263614cdd29f2f93cba85e992f041b31f9fc7b4033692f31269489a8a1b177; check_sha "$e/licenses/$p/share/licenses/libwinpthread/COPYING.MinGW-w64-runtime.txt" 1db8da07b436c68833c0673ffee3d9fcb2526047f3820b81661865dfedc79a1f; grep -Fq 'mingw-w64-libraries/winpthreads/configure' "$root/PKGBUILD" ;;
    *gcc-libs) check_sha "$e/licenses/$p/share/licenses/gcc-libs/COPYING.LIB" a9bdde5616ecdd1e980b44f360600ee8783b1f99b8cc83a2beb163a0a390e861; check_sha "$e/licenses/$p/share/licenses/gcc-libs/COPYING.RUNTIME" 9d6b43ce4d8de0c878bf16b54d8e7a10d9bd42b75178153e3af6a815bdc90f74; check_sha "$e/licenses/$p/share/licenses/gcc-libs/COPYING3" 8ceb4b9ee5adedde47b31e975c1d90c73ad27b6b165a1dcd80c7c545eb65b903 ;;
  esac
  files=; while IFS=$'\t' read -r dll h; do check_sha "/mingw64/bin/$dll" "$h"; files="${files}${files:+,}$dll"; done < <(awk -F '\t' -v p="$p" 'NR>1&&$5==p{print $1"\t"$2}' "$e/runtime-manifest.tsv" | sort); [ -n "$files" ]
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tVERIFIED\n' "$p" "$v" "$ssha" "$psha" "$nsha" "$class" "$files" "$lc" >> "$scratch/report"
done < "$scratch/packages.tsv"
awk -F '\t' -v OFS='\t' 'NR==FNR{if(FNR>1)p[$1 SUBSEP $2]=$5;next}FNR==1{print;next}(($1 SUBSEP $2)in p){$6=p[$1 SUBSEP $2];$7="VERIFIED";n++}{print}END{if(n!=3)exit 1}' "$scratch/packages.tsv" "$index" > "$scratch/index"
cp "$index" "$backup"; mv "$scratch/index" "$index"; mv "$scratch/report" "$verification"
echo "Promoted the final three Windows source packages."
