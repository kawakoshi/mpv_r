#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 audited-pre-fix-evidence fresh-fixed-evidence output-evidence" >&2
  exit 2
fi

old=$1
new=$2
output=$3
[ -d "$old" ] || { echo "Missing audited evidence: $old" >&2; exit 1; }
[ -d "$new" ] || { echo "Missing fixed evidence: $new" >&2; exit 1; }
[ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 1; }

for e in "$old" "$new"; do
  for required in runtime-manifest.tsv source-index.tsv license-manifest.tsv mpv-source.txt \
    build-environment.txt meson-buildoptions.json meson-dependencies.json ldd licenses package-metadata; do
    [ -e "$e/$required" ] || { echo "Missing evidence item: $e/$required" >&2; exit 1; }
  done
done
for required in source-packages ggml-source-verification-v1.tsv ggml-runtime-backend-gap-v1.tsv; do
  [ -e "$old/$required" ] || { echo "Missing audited item: $old/$required" >&2; exit 1; }
done

scratch=$(mktemp -d)
cleanup() { rm -rf "$scratch"; }
trap cleanup EXIT

normalized_source_set() {
  awk -F '\t' 'NR > 1 {print $1 "\t" $2}' "$1/source-index.tsv" | sort
}
normalized_runtime_package_set() {
  awk -F '\t' 'NR > 1 && $5 ~ /^mingw-w64-/ {print $5 "\t" $6}' "$1/runtime-manifest.tsv" | sort -u
}
normalized_source_set "$old" > "$scratch/old-source-set"
normalized_source_set "$new" > "$scratch/new-source-set"
normalized_runtime_package_set "$old" > "$scratch/old-runtime-set"
normalized_runtime_package_set "$new" > "$scratch/new-runtime-set"

old_source_sha=$(sha256sum "$scratch/old-source-set"); old_source_sha=${old_source_sha%% *}
new_source_sha=$(sha256sum "$scratch/new-source-set"); new_source_sha=${new_source_sha%% *}
old_runtime_sha=$(sha256sum "$scratch/old-runtime-set"); old_runtime_sha=${old_runtime_sha%% *}
new_runtime_sha=$(sha256sum "$scratch/new-runtime-set"); new_runtime_sha=${new_runtime_sha%% *}
[ "$old_source_sha" = "$new_source_sha" ] || { echo "Source package/version sets differ." >&2; exit 1; }
[ "$old_runtime_sha" = "$new_runtime_sha" ] || { echo "Runtime package/version sets differ." >&2; exit 1; }

old_commit=$(awk -F= '$1 == "head_commit" {print $2}' "$old/mpv-source.txt")
new_commit=$(awk -F= '$1 == "head_commit" {print $2}' "$new/mpv-source.txt")
old_describe=$(awk -F= '$1 == "describe" {print $2}' "$old/mpv-source.txt")
new_describe=$(awk -F= '$1 == "describe" {print $2}' "$new/mpv-source.txt")
[ -n "$old_commit" ] && [ "$old_commit" = "$new_commit" ] || { echo "mpv commits differ." >&2; exit 1; }
[ -n "$old_describe" ] && [ "$old_describe" = "$new_describe" ] || { echo "mpv descriptions differ." >&2; exit 1; }

awk -F '\t' 'NR > 1 {print $1 "\t" $2 "\t" $9}' "$old/runtime-manifest.tsv" | sort > "$scratch/old-files"
awk -F '\t' 'NR > 1 {print $1 "\t" $2 "\t" $9}' "$new/runtime-manifest.tsv" | sort > "$scratch/new-files"
awk -F '\t' 'NR == FNR {old[$1]=$2; old_kind[$1]=$3; next}
  !($1 in old) {if ($1 !~ /^ggml-cpu-.*\.dll$/ || $3 != "MSYS2_PACKAGE_IDENTIFIED") bad=1; else added++}
  $1 in old && $2 != old[$1] && ($3 != "SOURCE_BUILD" || old_kind[$1] != "SOURCE_BUILD") {bad=1}
  END {if (bad || added != 14) exit 1}' "$scratch/old-files" "$scratch/new-files" || {
  echo "The fixed runtime contains an unexpected addition or changed dependency." >&2
  exit 1
}
awk -F '\t' 'NR == FNR {new[$1]=1; next} !($1 in new) {bad=1} END {exit bad}' \
  "$scratch/new-files" "$scratch/old-files" || { echo "The fixed runtime removed an existing file." >&2; exit 1; }
grep -q $'^ggml-cpu-x64.dll\t' "$scratch/new-files"

cp -a "$old" "$output"
for file in runtime-manifest.tsv build-environment.txt mpv-source.txt mpv-source.patch \
  meson-buildoptions.json meson-dependencies.json; do
  cp "$new/$file" "$output/$file"
done
cp -a "$new/ldd/." "$output/ldd/"
cp -a "$new/package-metadata/." "$output/package-metadata/"

printf 'file\tsha256\tstatus\n' > "$output/ggml-runtime-backend-resolution-v1.tsv"
awk -F '\t' 'NR > 1 && $1 ~ /^ggml-cpu-.*\.dll$/ {print $1 "\t" $2 "\tINCLUDED_IN_FIXED_RUNTIME"}' \
  "$new/runtime-manifest.tsv" >> "$output/ggml-runtime-backend-resolution-v1.tsv"
awk -F '\t' 'BEGIN {OFS="\t"}
  NR == 1 {print; next}
  {$6=16; $7="CPU_BACKENDS_INCLUDED_REBUILD_VERIFIED"; print}' \
  "$old/ggml-source-verification-v1.tsv" > "$output/ggml-source-verification-v2.tsv"
printf 'field\tvalue\nsource_package_set_sha256\t%s\nruntime_package_set_sha256\t%s\nmpv_head_commit\t%s\nmpv_describe\t%s\nadded_ggml_cpu_dlls\t14\nstatus\tAUDIT_EVIDENCE_MERGED_AFTER_FIXED_REBUILD\n' \
  "$new_source_sha" "$new_runtime_sha" "$new_commit" "$new_describe" \
  > "$output/ggml-fixed-evidence-merge-v1.tsv"

echo "Merged audited source/license evidence with the fixed runtime capture: $output"
