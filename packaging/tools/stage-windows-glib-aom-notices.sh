#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 1 ]; then echo "Usage: $0 windows-evidence-dir" >&2; exit 2; fi
export LC_ALL=C
e=$1; manifest="$e/license-manifest.tsv"
backup="$e/license-manifest.pre-glib-aom-notices.tsv"
report="$e/glib-aom-notice-staging-v1.tsv"
correction="$e/glib-symlink-license-correction-v1.tsv"
for f in "$manifest" "$e/remaining-license-candidate-review-v1.tsv" "$e/remaining-nested-license-build-triage-v4.tsv"; do [ -f "$f" ] || { echo "Missing: $f" >&2; exit 1; }; done
for f in "$backup" "$report" "$correction"; do [ ! -e "$f" ] || { echo "Refusing to overwrite: $f" >&2; exit 1; }; done
scratch=$(mktemp -d "$e/.glib-aom-notices.XXXXXX"); trap 'rm -rf "$scratch"' EXIT
check_sha(){ local h; h=$(sha256sum "$1"); h=${h%% *}; [ "$h" = "$2" ] || { echo "SHA-256 mismatch: $1" >&2; exit 1; }; }
cp "$manifest" "$scratch/manifest.tsv"
printf 'package\tversion\tsource_member\tsha256\tdestination\treason\tstatus\n' > "$scratch/report.tsv"

stage_candidate(){
  local package=$1 version=$2 member=$3 sha=$4 old_count=$5 new_count=$6 destination=$7 reason=$8 extracted actual staged_count
  extracted=$(awk -F '\t' -v p="$package" -v v="$version" -v m="$member" -v h="$sha" 'NR>1&&$1==p&&$2==v&&$4==m{if($6!=h||$7!="NESTED_SOURCE_TEXT"||$8!="NEEDS_CONTENT_AND_BUILD_REVIEW")exit 1;print $5;n++}END{if(n!=1)exit 1}' "$e/remaining-license-candidate-review-v1.tsv")
  awk -F '\t' -v p="$package" -v v="$version" -v m="$member" -v h="$sha" 'NR>1&&$1==p&&$2==v&&$3==m{if($4!=h||$5!="BUILD_COMPONENT_REVIEW_PENDING")exit 1;n++}END{if(n!=1)exit 1}' "$e/remaining-nested-license-build-triage-v4.tsv"
  check_sha "$e/$extracted" "$sha"; actual=$(find "$e/licenses/$package" -type f | wc -l | tr -d '[:space:]'); staged_count=0
  if [ -d "$scratch/staged/$package" ]; then staged_count=$(find "$scratch/staged/$package" -type f | wc -l | tr -d '[:space:]'); fi
  [ "$((actual + staged_count))" = "$old_count" ]
  mkdir -p "$scratch/staged/$package/$(dirname "$destination")"; cp "$e/$extracted" "$scratch/staged/$package/$destination"; check_sha "$scratch/staged/$package/$destination" "$sha"
  awk -F '\t' -v OFS='\t' -v p="$package" -v v="$version" -v o="$old_count" -v n="$new_count" '$1==p&&$2==v{if($3!=o||$4!="COLLECTED")exit 1;$3=n;c++}{print}END{if(c!=1)exit 1}' "$scratch/manifest.tsv" > "$scratch/next"; mv "$scratch/next" "$scratch/manifest.tsv"
  printf '%s\t%s\t%s\t%s\t%s\t%s\tSTAGED\n' "$package" "$version" "$member" "$sha" "$destination" "$reason" >> "$scratch/report.tsv"
}

# The source archive stores COPYING and gmodule/COPYING as symlinks.  The
# earlier Windows extraction preserved their names but produced empty files.
# Verify the links and their real target without modifying the historical TSVs.
package=mingw-w64-x86_64-glib2; version=2.88.1-1; archive="$e/source-packages/$package-$version.src.tar.zst"
check_sha "$archive" 61bb8c11aaec4cbd1ded231ffb90d421d77a38f27aafff73cffbe49e3a640cb3
mkdir -p "$scratch/glib-source"; tar xf "$archive" -C "$scratch/glib-source"; outer=$(find "$scratch/glib-source" -mindepth 1 -maxdepth 1 -type d | head -n1); nested=$(find "$outer" -type f -name 'glib-2.88.1.tar.xz'); [ -f "$nested" ]
tar -tvf "$nested" glib-2.88.1/COPYING | grep -Fq -- '-> LICENSES/LGPL-2.1-or-later.txt'
tar -tvf "$nested" glib-2.88.1/gmodule/COPYING | grep -Fq -- '-> ../LICENSES/LGPL-2.1-or-later.txt'
tar -xOf "$nested" glib-2.88.1/LICENSES/LGPL-2.1-or-later.txt > "$scratch/glib-lgpl.txt"
check_sha "$scratch/glib-lgpl.txt" fa6f36630bb1e0c571d34b2bbdf188d08495c9dbf58f28cac112f303fc1f58fb
check_sha "$e/licenses/$package/share/licenses/glib2/COPYING" fa6f36630bb1e0c571d34b2bbdf188d08495c9dbf58f28cac112f303fc1f58fb
printf 'package\tversion\tsource_member\textraction_artifact_sha256\tactual_target\tactual_sha256\tstaged_match\tstatus\n' > "$scratch/correction.tsv"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\tCORRECTED_SYMLINK_EXTRACTION_ARTIFACT\n' "$package" "$version" glib-2.88.1/COPYING e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 glib-2.88.1/LICENSES/LGPL-2.1-or-later.txt fa6f36630bb1e0c571d34b2bbdf188d08495c9dbf58f28cac112f303fc1f58fb licenses/mingw-w64-x86_64-glib2/share/licenses/glib2/COPYING >> "$scratch/correction.tsv"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\tCORRECTED_SYMLINK_EXTRACTION_ARTIFACT\n' "$package" "$version" glib-2.88.1/gmodule/COPYING e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 glib-2.88.1/LICENSES/LGPL-2.1-or-later.txt fa6f36630bb1e0c571d34b2bbdf188d08495c9dbf58f28cac112f303fc1f58fb licenses/mingw-w64-x86_64-glib2/share/licenses/glib2/COPYING >> "$scratch/correction.tsv"

stage_candidate mingw-w64-x86_64-glib2 2.88.1-1 glib-2.88.1/subprojects/gvdb/COPYING bdbcdaa7858872393e9d6b216bbdc8a23e99d98dd6cdb7cda19458025b9e19fc 1 2 share/licenses/glib2/gvdb/COPYING gvdb_sources_are_compiled_into_shipped_libgio
stage_candidate mingw-w64-x86_64-aom 3.14.1-1 libaom-3.14.1/third_party/fastfeat/LICENSE 499041ddee5227b6f29ca06c17803e5fe24d60f243c69635cd76b7ba08d0ddd5 2 3 share/licenses/aom/third_party/fastfeat/LICENSE fastfeat_sources_are_compiled_into_libaom_encoder
stage_candidate mingw-w64-x86_64-aom 3.14.1-1 libaom-3.14.1/third_party/vector/LICENSE ff6c857ce2708e87701323078aef115c1872a1f80a9649f86dc899b48083bc60 3 4 share/licenses/aom/third_party/vector/LICENSE vector_sources_are_compiled_into_libaom_encoder
stage_candidate mingw-w64-x86_64-aom 3.14.1-1 libaom-3.14.1/third_party/x86inc/LICENSE 719d8fa235f2068e0ae6d6a7dceb0a7720d7840f0f0ebed29957989e6ded3cd8 4 5 share/licenses/aom/third_party/x86inc/LICENSE x86inc_macros_generate_assembly_compiled_into_libaom

cp "$manifest" "$backup"
for d in "$scratch/staged"/*; do package=$(basename "$d"); cp -a "$d/." "$e/licenses/$package/"; done
mv "$scratch/manifest.tsv" "$manifest"; mv "$scratch/report.tsv" "$report"; mv "$scratch/correction.tsv" "$correction"
echo "Staged GLib GVDB and three AOM component notices; recorded the GLib symlink extraction correction."
