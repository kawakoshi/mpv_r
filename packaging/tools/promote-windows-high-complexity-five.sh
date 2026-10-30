#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 1 ]; then echo "Usage: $0 windows-evidence-dir" >&2; exit 2; fi
export LC_ALL=C
e=$1; index="$e/source-index.tsv"; backup="$e/source-index.pre-high-complexity-five.tsv"; verification="$e/high-complexity-five-verification-v1.tsv"
for f in "$index" "$e/runtime-manifest.tsv" "$e/license-manifest.tsv" "$e/remaining-source-audit-summary-v1.tsv" "$e/msys2-source-package-inspection.tsv" "$e/remaining-license-candidate-coverage-v1.tsv" "$e/remaining-nested-license-build-triage-v4.tsv" "$e/glib-aom-notice-staging-v1.tsv" "$e/glib-symlink-license-correction-v1.tsv"; do [ -f "$f" ] || { echo "Missing: $f" >&2; exit 1; }; done
for f in "$backup" "$verification"; do [ ! -e "$f" ] || { echo "Refusing to overwrite: $f" >&2; exit 1; }; done
scratch=$(mktemp -d "$e/.high-complexity-five.XXXXXX"); trap 'rm -rf "$scratch"' EXIT
cat > "$scratch/packages.tsv" <<'ROWS'
package	version	source_sha256	patch_count	patch_set_sha256	root_count	nested_count	nested_set_sha256	license_count	classification
mingw-w64-x86_64-glib2	2.88.1-1	61bb8c11aaec4cbd1ded231ffb90d421d77a38f27aafff73cffbe49e3a640cb3	3	dcc4c364e1b57d2aebd425435e557da9411ecc4ee2a168b768ee380fa79f6ba6	1	3	1251aa6baab7791886b984b5c0147657b3758efd42c3d7dfd7b1c973cbba807f	2	GVDB_STAGED_GMODULE_COVERED_DOCS_EXCLUDED_SYMLINK_ARTIFACT_CORRECTED
mingw-w64-x86_64-libjxl	0.11.2-4	4c627cb0839aed3fd056adf7fafc57be47094960219979709989002731ccdf92	0	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855	1	3	a492153679cbc2e0790497ecaf74356ad9705d3cd139ef7c929788997b99e0ba	1	DEBIAN_METADATA_HEVC_CONFIG_AND_STATIC_EXTRAS_NOT_SHIPPED_DLLS
mingw-w64-x86_64-openjpeg2	2.5.4-2	88be024421b79a557ea9cc94932806f5daddcae5d917895d81ac974df7f38b24	3	07a246a395c80f4fe2d87588f78fcf44900f049851b15393ede20120d381ca2e	1	4	276ae7d5dc54152e2952651a72158c0b8940f0e0d4b4da70c93884ef419ffcfe	1	VIEWER_FORMATTER_AND_BUNDLED_FALLBACK_LIBRARIES_NOT_IN_SHIPPED_DLL
mingw-w64-x86_64-cairo	1.18.4-4	3a83c94fd2818872441db8ded3e500aa1401e673fa389390b8423be954bafea2	2	86f65b8599fc26450ec7d9137baa2c205f76ed21d4606b7561f4bef663a08048	1	5	255992571531ee46905d43961239c86d5083cc8da9a6693e498e9778f97f1ff6	3	PERF_DISABLED_UTIL_LIBRARIES_AND_TOOLS_NOT_SHIPPED
mingw-w64-x86_64-aom	3.14.1-1	420b80c94cf52cd4197616a71f0df90ee2def4659828a89496e8b7f92def16d3	0	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855	1	6	aaca86a635494d4202918a5ec4dce52a7e7600b24fb67c03af121a88724e0975	5	FASTFEAT_VECTOR_X86INC_STAGED_GOOGLETEST_LIBWEBM_LIBYUV_EXCLUDED
ROWS
check_sha(){ local h; h=$(sha256sum "$1"); h=${h%% *}; [ "$h" = "$2" ] || { echo "SHA mismatch: $1" >&2; exit 1; }; }
printf 'package\tversion\tsource_sha256\tpatch_set_sha256\tnested_set_sha256\tclassification\truntime_files\tlicense_count\tstatus\n' > "$scratch/report"
while IFS=$'\t' read -r p v ssha pc psha roots nested nsha lc class; do
  [ "$p" = package ] && continue
  a="$e/source-packages/$p-$v.src.tar.zst"; check_sha "$a" "$ssha"
  url=$(awk -F '\t' -v p="$p" -v v="$v" -v h="$ssha" 'NR>1&&$1==p&&$2==v{if($3!="STANDARD_ARCHIVE"||$5!=h||$7!="UPSTREAM_SHA_MATCH"||$8!="LICENSE_REVIEW_PENDING")exit 1;print $4;n++}END{if(n!=1)exit 1}' "$e/remaining-source-audit-summary-v1.tsv")
  awk -F '\t' -v p="$p" -v v="$v" -v u="$url" 'NR>1&&$1==p&&$2==v{if($5!=u||$6!="MISSING"||$7!="PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION")exit 1;n++}END{if(n!=1)exit 1}' "$index"
  awk -F '\t' -v p="$p" -v v="$v" -v c="$pc" 'NR>1&&$1==p&&$2==v{if($5!=c)exit 1;n++}END{if(n!=1)exit 1}' "$e/msys2-source-package-inspection.tsv"
  awk -F '\t' -v p="$p" -v v="$v" -v r="$roots" -v n="$nested" 'NR>1&&$1==p&&$2==v{if($4!=r||$5!=n)exit 1;c++}END{if(c!=1)exit 1}' "$e/remaining-license-candidate-coverage-v1.tsv"
  d="$scratch/$p"; mkdir -p "$d"; tar xf "$a" -C "$d"; root=$(find "$d" -mindepth 1 -maxdepth 1 -type d | head -n1)
  : > "$d/patches"; for f in "$root"/*.patch; do [ -f "$f" ] || continue; h=$(sha256sum "$f"); printf '%s\t%s\n' "$(basename "$f")" "${h%% *}" >> "$d/patches"; done; sort -o "$d/patches" "$d/patches"; [ "$(wc -l < "$d/patches" | tr -d '[:space:]')" = "$pc" ]; check_sha "$d/patches" "$psha"
  awk -F '\t' -v p="$p" 'NR>1&&$1==p{print $3"\t"$4"\t"$5}' "$e/remaining-nested-license-build-triage-v4.tsv" | sort > "$d/nested"; [ "$(wc -l < "$d/nested" | tr -d '[:space:]')" = "$nested" ]; check_sha "$d/nested" "$nsha"
  recorded=$(awk -F '\t' -v p="$p" -v v="$v" 'NR>1&&$1==p&&$2==v{if($4!="COLLECTED")exit 1;print $3;n++}END{if(n!=1)exit 1}' "$e/license-manifest.tsv"); actual=$(find "$e/licenses/$p" -type f | wc -l | tr -d '[:space:]'); [ "$recorded" = "$lc" ]; [ "$actual" = "$lc" ]
  case "$p" in
    *glib2) check_sha "$e/licenses/$p/share/licenses/glib2/gvdb/COPYING" bdbcdaa7858872393e9d6b216bbdc8a23e99d98dd6cdb7cda19458025b9e19fc; [ "$(awk 'END{print NR}' "$e/glib-symlink-license-correction-v1.tsv")" = 3 ] ;;
    *aom) check_sha "$e/licenses/$p/share/licenses/aom/third_party/fastfeat/LICENSE" 499041ddee5227b6f29ca06c17803e5fe24d60f243c69635cd76b7ba08d0ddd5; check_sha "$e/licenses/$p/share/licenses/aom/third_party/vector/LICENSE" ff6c857ce2708e87701323078aef115c1872a1f80a9649f86dc899b48083bc60; check_sha "$e/licenses/$p/share/licenses/aom/third_party/x86inc/LICENSE" 719d8fa235f2068e0ae6d6a7dceb0a7720d7840f0f0ebed29957989e6ded3cd8 ;;
  esac
  files=; while IFS=$'\t' read -r dll h; do check_sha "/mingw64/bin/$dll" "$h"; files="${files}${files:+,}$dll"; done < <(awk -F '\t' -v p="$p" 'NR>1&&$5==p{print $1"\t"$2}' "$e/runtime-manifest.tsv" | sort); [ -n "$files" ]
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tVERIFIED\n' "$p" "$v" "$ssha" "$psha" "$nsha" "$class" "$files" "$lc" >> "$scratch/report"
done < "$scratch/packages.tsv"
awk -F '\t' -v OFS='\t' 'NR==FNR{if(FNR>1)p[$1 SUBSEP $2]=$3;next}FNR==1{print;next}(($1 SUBSEP $2)in p){$6=p[$1 SUBSEP $2];$7="VERIFIED";n++}{print}END{if(n!=5)exit 1}' "$scratch/packages.tsv" "$index" > "$scratch/index"
cp "$index" "$backup"; mv "$scratch/index" "$index"; mv "$scratch/report" "$verification"
echo "Promoted five high-complexity packages after component-level review."
