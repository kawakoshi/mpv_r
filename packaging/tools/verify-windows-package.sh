#!/usr/bin/env sh
set -eu

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 package.zip windows-evidence-dir" >&2
  exit 2
fi

archive=$1
evidence=$2
[ -f "$archive" ] || { echo "Package not found: $archive" >&2; exit 1; }
[ -d "$evidence" ] || { echo "Evidence not found: $evidence" >&2; exit 1; }

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
"$script_dir/verify-windows-selfbuild-evidence.sh" "$evidence"

work=$(mktemp -d "${TMPDIR:-/tmp}/mpv-r-windows-package.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM

if command -v bsdtar >/dev/null 2>&1; then
  list_archive() { bsdtar -tf "$archive"; }
  extract_archive() { bsdtar -xf "$archive" -C "$work"; }
elif command -v unzip >/dev/null 2>&1; then
  list_archive() { unzip -Z1 "$archive"; }
  extract_archive() { unzip -q "$archive" -d "$work"; }
else
  echo "bsdtar or unzip is required to verify the ZIP" >&2
  exit 1
fi

if list_archive | awk '/^\// || /(^|\/)\.\.($|\/)/ {bad=1} END {exit bad ? 0 : 1}'; then
  echo "Unsafe path found in ZIP" >&2
  exit 1
fi
extract_archive

package="$work/mpv_r"
[ -d "$package" ] || { echo "Top-level mpv_r directory missing" >&2; exit 1; }
[ "$(find "$work" -mindepth 1 -maxdepth 1 | wc -l | tr -d '[:space:]')" = 1 ] || { echo "Unexpected top-level ZIP entries" >&2; exit 1; }

for required in \
  mpv_r.exe \
  resources/mpv/mpv.exe \
  resources/mpv/mpv.com \
  resources/mpv/libmpv-2.dll \
  resources/mpv/ggml-cpu-x64.dll \
  register-file-associations.cmd \
  create-desktop-shortcut.cmd \
  documents/README.txt \
  documents/NOTICE.txt \
  documents/LICENSES/windows-selfbuild/runtime-manifest.tsv \
  documents/LICENSES/windows-selfbuild/license-manifest.tsv \
  documents/LICENSES/windows-selfbuild/source-index.tsv \
  documents/LICENSES/windows-selfbuild/final-package-runtime-manifest.tsv \
  documents/LICENSES/windows-selfbuild/licenses/mingw-w64-x86_64-libwinpthread/share/licenses/libwinpthread/COPYING.MinGW-w64-runtime.txt; do
  [ -f "$package/$required" ] || { echo "Required package file missing: $required" >&2; exit 1; }
done

embedded="$package/documents/LICENSES/windows-selfbuild"
hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi
}
same_file() {
  [ "$(hash_file "$1")" = "$(hash_file "$2")" ]
}
for manifest in runtime-manifest.tsv license-manifest.tsv source-index.tsv; do
  same_file "$evidence/$manifest" "$embedded/$manifest" || { echo "Embedded $manifest differs from evidence" >&2; exit 1; }
done

expected_runtime="$work/expected-runtime.tsv"
actual_runtime="$work/actual-runtime.tsv"
awk -F '\t' 'NR>1 {print $1 "\t" $2 "\t" $3}' "$evidence/runtime-manifest.tsv" | sort > "$expected_runtime"
: > "$actual_runtime"
while IFS="$(printf '\t')" read -r name expected_sha expected_bytes; do
  file="$package/resources/mpv/$name"
  [ -f "$file" ] || { echo "Manifest runtime missing from ZIP: $name" >&2; exit 1; }
  sha=$(hash_file "$file"); bytes=$(wc -c < "$file" | tr -d '[:space:]')
  [ "$sha" = "$expected_sha" ] || { echo "Runtime SHA mismatch: $name" >&2; exit 1; }
  [ "$bytes" = "$expected_bytes" ] || { echo "Runtime size mismatch: $name" >&2; exit 1; }
  printf '%s\t%s\t%s\n' "$name" "$sha" "$bytes" >> "$actual_runtime"
done < "$expected_runtime"
sort -o "$actual_runtime" "$actual_runtime"
find "$package/resources/mpv" -maxdepth 1 -type f \( -iname '*.exe' -o -iname '*.com' -o -iname '*.dll' \) -print | \
  while IFS= read -r file; do basename "$file"; done | sort > "$work/runtime-files"
cut -f1 "$expected_runtime" > "$work/runtime-expected-names"
same_file "$work/runtime-expected-names" "$work/runtime-files" || { echo "ZIP runtime file set differs from runtime manifest" >&2; exit 1; }

final_manifest="$embedded/final-package-runtime-manifest.tsv"
awk -F '\t' 'NR>1 {print $1 "\t" $2 "\t" $3}' "$final_manifest" | sort > "$work/final-expected"
: > "$work/final-actual"
while IFS="$(printf '\t')" read -r relative expected_sha expected_bytes; do
  file="$package/$relative"
  [ -f "$file" ] || { echo "Final manifest file missing: $relative" >&2; exit 1; }
  sha=$(hash_file "$file"); bytes=$(wc -c < "$file" | tr -d '[:space:]')
  [ "$sha" = "$expected_sha" ] || { echo "Final package SHA mismatch: $relative" >&2; exit 1; }
  [ "$bytes" = "$expected_bytes" ] || { echo "Final package size mismatch: $relative" >&2; exit 1; }
  printf '%s\t%s\t%s\n' "$relative" "$sha" "$bytes" >> "$work/final-actual"
done < "$work/final-expected"
sort -o "$work/final-actual" "$work/final-actual"
find "$package" -type f \( -iname '*.exe' -o -iname '*.com' -o -iname '*.dll' \) -print | \
  sed "s#^$package/##" | sort > "$work/final-files"
cut -f1 "$work/final-expected" > "$work/final-expected-names"
same_file "$work/final-expected-names" "$work/final-files" || { echo "ZIP binary set differs from final package manifest" >&2; exit 1; }

awk -F '\t' 'NR>1 && $7!="VERIFIED" {bad=1} END {exit bad}' "$embedded/source-index.tsv" || { echo "Embedded source index has unverified rows" >&2; exit 1; }
while IFS="$(printf '\t')" read -r owner version count status; do
  [ "$owner" = package ] && continue
  [ "$status" = COLLECTED ] || { echo "Uncollected license row: $owner" >&2; exit 1; }
  actual=$(find "$embedded/licenses/$owner" -type f | wc -l | tr -d '[:space:]')
  [ "$actual" = "$count" ] || { echo "Embedded license count mismatch: $owner" >&2; exit 1; }
done < "$embedded/license-manifest.tsv"

runtime_count=$(awk 'END{print NR-1}' "$evidence/runtime-manifest.tsv")
final_count=$(awk 'END{print NR-1}' "$final_manifest")
[ "$final_count" -eq $((runtime_count + 1)) ] || { echo "Final manifest must contain runtime plus launcher" >&2; exit 1; }

archive_sha=$(hash_file "$archive")
archive_bytes=$(wc -c < "$archive" | tr -d '[:space:]')
printf 'Windows package verified: runtime=%s final-binaries=%s licenses=%s bytes=%s sha256=%s\n' \
  "$runtime_count" "$final_count" "$(find "$embedded/licenses" -type f | wc -l | tr -d '[:space:]')" "$archive_bytes" "$archive_sha"
