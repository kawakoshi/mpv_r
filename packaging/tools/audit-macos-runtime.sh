#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 /path/to/mpv_r.app output-directory" >&2
  exit 2
fi

app=$1
output_dir=$2
if [ ! -d "$app/Contents" ]; then
  echo "Not an app bundle: $app" >&2
  exit 2
fi

brew_prefix=$(brew --prefix)
mkdir -p "$output_dir"
runtime_list=$(mktemp "${TMPDIR:-/tmp}/mpv-r-macos-runtime.XXXXXX")
index=$(mktemp "${TMPDIR:-/tmp}/mpv-r-homebrew-libs.XXXXXX")
trap 'rm -f "$runtime_list" "$index"' EXIT

find "$app/Contents" -type f \( -name '*.dylib' -o -path '*/MacOS/mpv' \) -print0 \
  | sort -z > "$runtime_list"
find -L "$brew_prefix/opt" -path '*/lib/*.dylib' -type f -print 2>/dev/null \
  | while IFS= read -r path; do printf '%s\t%s\n' "$(basename "$path")" "$path"; done \
  | sort -u > "$index"

printf 'bundle_path\tsha256\tformula\tformula_version\tmatched_keg_path\tkeg_sha256\tkeg_content_match\n' \
  > "$output_dir/runtime-manifest.tsv"
: > "$output_dir/linkage.txt"

while IFS= read -r -d '' runtime; do
  base=$(basename "$runtime")
  bundle_hash=$(shasum -a 256 "$runtime" | awk '{print $1}')
  candidate=$(awk -F '\t' -v base="$base" '$1 == base {print $2; exit}' "$index")
  formula=UNMAPPED
  version=UNMAPPED
  candidate_hash=UNMAPPED
  match=UNMAPPED
  if [ "$base" = mpv ] && [ "${runtime#$app/}" = 'Contents/MacOS/mpv' ]; then
    formula=mpv-player/mpv
    version=${MPV_SOURCE_TAG:-UNRECORDED}
    candidate=SOURCE_BUILD
    candidate_hash=N/A
    match=N/A
  elif [ -n "$candidate" ]; then
    resolved=$(realpath "$candidate")
    candidate_hash=$(shasum -a 256 "$resolved" | awk '{print $1}')
    relative=${resolved#"$brew_prefix/Cellar/"}
    formula=${relative%%/*}
    remainder=${relative#*/}
    version=${remainder%%/*}
    if [ "$bundle_hash" = "$candidate_hash" ]; then match=yes; else match=no; fi
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "${runtime#$app/}" "$bundle_hash" "$formula" "$version" \
    "${candidate:-UNMAPPED}" "$candidate_hash" "$match" \
    >> "$output_dir/runtime-manifest.tsv"
  printf '## %s\n' "${runtime#$app/}" >> "$output_dir/linkage.txt"
  otool -L "$runtime" >> "$output_dir/linkage.txt"
  printf '\n' >> "$output_dir/linkage.txt"
done < "$runtime_list"

echo "Wrote: $output_dir/runtime-manifest.tsv"
echo "Wrote: $output_dir/linkage.txt"
