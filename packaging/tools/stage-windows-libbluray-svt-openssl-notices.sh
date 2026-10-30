#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 1 ]; then echo "Usage: $0 windows-evidence-dir" >&2; exit 2; fi
e=$1; manifest="$e/license-manifest.tsv"
backup="$e/license-manifest.pre-libbluray-svt-openssl-notices.tsv"
report="$e/libbluray-svt-openssl-notice-staging-v1.tsv"
for f in "$manifest" "$e/remaining-license-candidate-review-v1.tsv" "$e/remaining-nested-license-build-triage-v4.tsv"; do [ -f "$f" ] || { echo "Missing: $f" >&2; exit 1; }; done
for f in "$backup" "$report"; do [ ! -e "$f" ] || { echo "Refusing to overwrite: $f" >&2; exit 1; }; done
scratch=$(mktemp -d "$e/.three-more-notices.XXXXXX"); trap 'rm -rf "$scratch"' EXIT
check_sha(){ local h; h=$(sha256sum "$1"); h=${h%% *}; [ "$h" = "$2" ] || { echo "SHA-256 mismatch: $1" >&2; exit 1; }; }
cp "$manifest" "$scratch/manifest.tsv"
printf 'package\tversion\tsource_member\tsha256\tdestination\treason\tstatus\n' > "$scratch/report.tsv"

stage_candidate(){
  local package=$1 version=$2 member=$3 sha=$4 old_count=$5 new_count=$6 destination=$7 reason=$8 extracted actual
  extracted=$(awk -F '\t' -v p="$package" -v v="$version" -v m="$member" -v h="$sha" 'NR>1&&$1==p&&$2==v&&$4==m{if($6!=h||$7!="NESTED_SOURCE_TEXT"||$8!="NEEDS_CONTENT_AND_BUILD_REVIEW")exit 1;print $5;n++}END{if(n!=1)exit 1}' "$e/remaining-license-candidate-review-v1.tsv")
  awk -F '\t' -v p="$package" -v v="$version" -v m="$member" -v h="$sha" 'NR>1&&$1==p&&$2==v&&$3==m{if($4!=h||$5!="BUILD_COMPONENT_REVIEW_PENDING")exit 1;n++}END{if(n!=1)exit 1}' "$e/remaining-nested-license-build-triage-v4.tsv"
  check_sha "$e/$extracted" "$sha"; actual=$(find "$e/licenses/$package" -type f|wc -l|tr -d '[:space:]'); [ "$actual" = "$old_count" ]
  mkdir -p "$scratch/staged/$package/$(dirname "$destination")"; cp "$e/$extracted" "$scratch/staged/$package/$destination"; check_sha "$scratch/staged/$package/$destination" "$sha"
  awk -F '\t' -v OFS='\t' -v p="$package" -v v="$version" -v o="$old_count" -v n="$new_count" '$1==p&&$2==v{if($3!=o||$4!="COLLECTED")exit 1;$3=n;c++}{print}END{if(c!=1)exit 1}' "$scratch/manifest.tsv" > "$scratch/next"; mv "$scratch/next" "$scratch/manifest.tsv"
  printf '%s\t%s\t%s\t%s\t%s\t%s\tSTAGED\n' "$package" "$version" "$member" "$sha" "$destination" "$reason" >> "$scratch/report.tsv"
}
stage_candidate mingw-w64-x86_64-libbluray 1.4.1-1 libbluray-1.4.1/contrib/libudfread/COPYING dc626520dcd53a22f727af3ee42c770e56c97a64fe3adb063799d8ab032fe551 1 2 share/licenses/libbluray/libudfread/COPYING libudfread_is_statically_incorporated_into_libbluray
stage_candidate mingw-w64-x86_64-svt-av1 4.1.0-1 SVT-AV1-v4.1.0/third_party/fastfeat/LICENSE 043dcfd059386f9facd376351b2bd79325778744aa442177390cdfcca54babed 2 3 share/licenses/svt-av1/third_party/fastfeat/LICENSE fastfeat_headers_are_used_by_encoder_library_sources

package=mingw-w64-x86_64-openssl; version=3.6.3-1; archive="$e/source-packages/$package-$version.src.tar.zst"
check_sha "$archive" b8e8625cf89996d32c3d6c4db8a98c46de6558f5a4e7e98ae1287ec2d6a97e51
mkdir -p "$scratch/openssl-source"; tar xf "$archive" -C "$scratch/openssl-source"; root=$(find "$scratch/openssl-source" -mindepth 1 -maxdepth 1 -type d|head -n1)
check_sha "$root/pathtools.c" ebf471173f5ee9c4416c10a78760cea8afaf1a4a6e653977321e8547ce7bf3c0
check_sha "$root/pathtools.h" 1585ef1b61cf53a2ca27049c11d49e0834683dfda798f03547761375df482a90
sed -n '1,9p' "$root/pathtools.c" > "$scratch/PATHTOOLS-CC0-NOTICE.txt"
sed -n '1,9p' "$root/pathtools.h" > "$scratch/PATHTOOLS-CC0-NOTICE-h.txt"
check_sha "$scratch/PATHTOOLS-CC0-NOTICE.txt" 97122849dcb43bd9f9b9eb38f4dff2f7fd610f974758c6f597e5e211af08c965
check_sha "$scratch/PATHTOOLS-CC0-NOTICE-h.txt" 97122849dcb43bd9f9b9eb38f4dff2f7fd610f974758c6f597e5e211af08c965
grep -Fq 'cp -fHv "${srcdir}"/pathtools.c crypto/' "$root/PKGBUILD"
actual=$(find "$e/licenses/$package" -type f|wc -l|tr -d '[:space:]'); [ "$actual" = 1 ]
mkdir -p "$scratch/staged/$package/share/licenses/openssl"; cp "$scratch/PATHTOOLS-CC0-NOTICE.txt" "$scratch/staged/$package/share/licenses/openssl/PATHTOOLS-CC0-NOTICE.txt"
awk -F '\t' -v OFS='\t' -v p="$package" -v v="$version" '$1==p&&$2==v{if($3!=1||$4!="COLLECTED")exit 1;$3=2;n++}{print}END{if(n!=1)exit 1}' "$scratch/manifest.tsv" > "$scratch/next"; mv "$scratch/next" "$scratch/manifest.tsv"
printf '%s\t%s\t%s\t%s\t%s\t%s\tSTAGED\n' "$package" "$version" 'pathtools.c:1-9 and pathtools.h:1-9' 97122849dcb43bd9f9b9eb38f4dff2f7fd610f974758c6f597e5e211af08c965 share/licenses/openssl/PATHTOOLS-CC0-NOTICE.txt pathtools_sources_are_copied_into_openssl_crypto >> "$scratch/report.tsv"

cp "$manifest" "$backup"
for d in "$scratch/staged"/*; do package=$(basename "$d"); cp -a "$d/." "$e/licenses/$package/"; done
mv "$scratch/manifest.tsv" "$manifest"; mv "$scratch/report.tsv" "$report"
echo "Staged libudfread, SVT fastfeat, and OpenSSL pathtools notices."
