#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
evidence_dir=$1
index="$evidence_dir/source-index.tsv"
backup="$evidence_dir/source-index.pre-source-name-correction.tsv"
candidate="$evidence_dir/source-index.source-name-correction.tmp"
[ -f "$index" ] || { echo "Missing: $index" >&2; exit 2; }
for path in "$backup" "$candidate"; do
  [ ! -e "$path" ] || { echo "Refusing to overwrite: $path" >&2; exit 2; }
done

for mapping in \
  'gettext-runtime|gettext' \
  'libwinpthread|winpthreads' \
  'gcc-libs|gcc'; do
  binary=${mapping%%|*}
  source=${mapping#*|}
  package="mingw-w64-x86_64-$binary"
  version=$(awk -F '\t' -v p="$package" 'NR>1 && $1==p && $7=="PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION" {print $2}' "$index")
  [ -n "$version" ] || { echo "Pending package not found: $package" >&2; exit 1; }
  archive="$evidence_dir/source-packages/${package}-${version}.src.tar.zst"
  [ -f "$archive" ] || { echo "Missing source archive: $archive" >&2; exit 1; }
  if ! tar -xOf "$archive" "mingw-w64-$source/.SRCINFO" | \
    grep -q "^pkgbase = mingw-w64-$source$"; then
    echo "Source package identity mismatch: $package" >&2
    exit 1
  fi
done

awk -F '\t' 'BEGIN {OFS="\t"}
  NR==1 {print; next}
  $7=="PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION" {
    if ($1=="mingw-w64-x86_64-gettext-runtime") source="gettext"
    else if ($1=="mingw-w64-x86_64-libwinpthread") source="winpthreads"
    else if ($1=="mingw-w64-x86_64-gcc-libs") source="gcc"
    else source=""
    if (source!="") $5="https://repo.msys2.org/mingw/sources/mingw-w64-" source "-" $2 ".src.tar.zst"
  }
  {print}
' "$index" > "$candidate"
cp "$index" "$backup"
mv "$candidate" "$index"
echo "Corrected three pending source-package candidate URLs; previous index: $backup"
