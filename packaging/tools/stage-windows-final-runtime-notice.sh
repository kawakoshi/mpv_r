#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 1 ]; then echo "Usage: $0 windows-evidence-dir" >&2; exit 2; fi
export LC_ALL=C
e=$1; manifest="$e/license-manifest.tsv"
backup="$e/license-manifest.pre-final-runtime-notice.tsv"
report="$e/final-runtime-notice-staging-v1.tsv"
correction="$e/librsvg-symlink-license-correction-v1.tsv"
for f in "$manifest" "$e/remaining-license-candidate-review-v1.tsv" "$e/remaining-nested-license-build-triage-v4.tsv"; do [ -f "$f" ] || { echo "Missing: $f" >&2; exit 1; }; done
for f in "$backup" "$report" "$correction"; do [ ! -e "$f" ] || { echo "Refusing to overwrite: $f" >&2; exit 1; }; done
scratch=$(mktemp -d "$e/.final-runtime-notice.XXXXXX"); trap 'rm -rf "$scratch"' EXIT
check_sha(){ local h; h=$(sha256sum "$1"); h=${h%% *}; [ "$h" = "$2" ] || { echo "SHA-256 mismatch: $1" >&2; exit 1; }; }
cp "$manifest" "$scratch/manifest.tsv"

# MinGW-w64 says this notice should accompany binary packages which contain
# statically linked portions of its runtime.  The portable bundle does so.
p=mingw-w64-x86_64-libwinpthread; v=14.0.0.r147.g31bd54ab7-1; member=COPYING.MinGW-w64-runtime/COPYING.MinGW-w64-runtime.txt; sha=1db8da07b436c68833c0673ffee3d9fcb2526047f3820b81661865dfedc79a1f
extracted=$(awk -F '\t' -v p="$p" -v v="$v" -v m="$member" -v h="$sha" 'NR>1&&$1==p&&$2==v&&$4==m{if($6!=h||$7!="NESTED_SOURCE_TEXT")exit 1;print $5;n++}END{if(n!=1)exit 1}' "$e/remaining-license-candidate-review-v1.tsv")
awk -F '\t' -v p="$p" -v v="$v" -v m="$member" -v h="$sha" 'NR>1&&$1==p&&$2==v&&$3==m{if($4!=h||$5!="BUILD_COMPONENT_REVIEW_PENDING")exit 1;n++}END{if(n!=1)exit 1}' "$e/remaining-nested-license-build-triage-v4.tsv"
check_sha "$e/$extracted" "$sha"; [ "$(find "$e/licenses/$p" -type f | wc -l | tr -d '[:space:]')" = 1 ]
dest=share/licenses/libwinpthread/COPYING.MinGW-w64-runtime.txt; mkdir -p "$scratch/staged/$p/$(dirname "$dest")"; cp "$e/$extracted" "$scratch/staged/$p/$dest"; check_sha "$scratch/staged/$p/$dest" "$sha"
awk -F '\t' -v OFS='\t' -v p="$p" -v v="$v" '$1==p&&$2==v{if($3!=1||$4!="COLLECTED")exit 1;$3=2;n++}{print}END{if(n!=1)exit 1}' "$scratch/manifest.tsv" > "$scratch/next"; mv "$scratch/next" "$scratch/manifest.tsv"
printf 'package\tversion\tsource_member\tsha256\tdestination\treason\tstatus\n%s\t%s\t%s\t%s\t%s\t%s\tSTAGED\n' "$p" "$v" "$member" "$sha" "$dest" MINGW_RUNTIME_NOTICE_APPLIES_TO_DISTRIBUTED_BINARIES > "$scratch/report.tsv"

# Seven librsvg candidates were symlinks which the earlier Windows text
# extractor represented as empty files.  Resolve each link against the fixed
# upstream archive and record whether its component is in the shipped DLL.
p=mingw-w64-x86_64-librsvg; v=2.62.3-1; archive="$e/source-packages/$p-$v.src.tar.zst"
check_sha "$archive" 6007e8f5960b63f2d71d6a8418bc414104c5c9998f741cd8f53e17a7cced41ac
mkdir -p "$scratch/librsvg-source"; tar xf "$archive" -C "$scratch/librsvg-source"; outer=$(find "$scratch/librsvg-source" -mindepth 1 -maxdepth 1 -type d | head -n1); nested=$(find "$outer" -type f -name 'librsvg-2.62.3.tar.xz'); [ -f "$nested" ]
cat > "$scratch/librsvg-links.tsv" <<'ROWS'
member	link_target	actual_member	actual_sha256	decision
librsvg-2.62.3/gdk-pixbuf-loader/COPYING.LIB	../COPYING.LIB	librsvg-2.62.3/COPYING.LIB	dc626520dcd53a22f727af3ee42c770e56c97a64fe3adb063799d8ab032fe551	ROOT_LICENSE_STAGED_LOADER_NOT_IN_PORTABLE_BUNDLE
librsvg-2.62.3/librsvg-c/COPYING.LIB	../COPYING.LIB	librsvg-2.62.3/COPYING.LIB	dc626520dcd53a22f727af3ee42c770e56c97a64fe3adb063799d8ab032fe551	ROOT_LICENSE_STAGED_RUNTIME_COMPONENT
librsvg-2.62.3/librsvg-rebind/librsvg-rebind/LICENSE	../LICENSE	librsvg-2.62.3/librsvg-rebind/LICENSE	f9c4c77baa3828004ee54a8f2db2e88ed44a6237a493965bf551fac0fcb62d	REBIND_WORKSPACE_CRATE_NOT_A_RUNTIME_DEPENDENCY
librsvg-2.62.3/librsvg-rebind/librsvg-rebind/sys/LICENSE	../../LICENSE	librsvg-2.62.3/librsvg-rebind/LICENSE	f9c4c77baa3828004ee54a8f2db2e88ed44a6237a493965bf551fac0fcb62d	REBIND_WORKSPACE_CRATE_NOT_A_RUNTIME_DEPENDENCY
librsvg-2.62.3/rsvg/COPYING.LIB	../COPYING.LIB	librsvg-2.62.3/COPYING.LIB	dc626520dcd53a22f727af3ee42c770e56c97a64fe3adb063799d8ab032fe551	ROOT_LICENSE_STAGED_RUNTIME_COMPONENT
librsvg-2.62.3/rsvg-bench/COPYING.LIB	../COPYING.LIB	librsvg-2.62.3/COPYING.LIB	dc626520dcd53a22f727af3ee42c770e56c97a64fe3adb063799d8ab032fe551	ROOT_LICENSE_STAGED_BENCHMARK_NOT_SHIPPED
librsvg-2.62.3/rsvg_convert/COPYING.LIB	../COPYING.LIB	librsvg-2.62.3/COPYING.LIB	dc626520dcd53a22f727af3ee42c770e56c97a64fe3adb063799d8ab032fe551	ROOT_LICENSE_STAGED_CONVERTER_NOT_IN_PORTABLE_BUNDLE
ROWS
printf 'package\tversion\tsource_member\textraction_artifact_sha256\tlink_target\tactual_member\tactual_sha256\tdecision\tstatus\n' > "$scratch/correction.tsv"
while IFS=$'\t' read -r source_member link_target actual_member actual_sha decision; do
  [ "$source_member" = member ] && continue
  tar -tvf "$nested" "$source_member" | grep -Fq -- "-> $link_target"
  tar -xOf "$nested" "$actual_member" > "$scratch/actual"; check_sha "$scratch/actual" "$actual_sha"
  awk -F '\t' -v p="$p" -v v="$v" -v m="$source_member" 'NR>1&&$1==p&&$2==v&&$3==m{if($4!="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")exit 1;n++}END{if(n!=1)exit 1}' "$e/remaining-nested-license-build-triage-v4.tsv"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tCORRECTED_SYMLINK_EXTRACTION_ARTIFACT\n' "$p" "$v" "$source_member" e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 "$link_target" "$actual_member" "$actual_sha" "$decision" >> "$scratch/correction.tsv"
done < "$scratch/librsvg-links.tsv"
check_sha "$e/licenses/$p/share/licenses/librsvg/COPYING.LIB" dc626520dcd53a22f727af3ee42c770e56c97a64fe3adb063799d8ab032fe551

cp "$manifest" "$backup"; cp -a "$scratch/staged/." "$e/licenses/"; mv "$scratch/manifest.tsv" "$manifest"; mv "$scratch/report.tsv" "$report"; mv "$scratch/correction.tsv" "$correction"
echo "Staged the MinGW runtime notice and recorded seven corrected librsvg symlinks."
