#!/usr/bin/env bash
set -euo pipefail

# Correct the 21 already reviewed packages whose source-index previously
# pointed to upstream tarballs instead of the patched MSYS2 source packages.
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 windows-evidence-dir msys2-source-package-verification.tsv" >&2
  exit 2
fi
evidence_dir=$1
verification=$2
index="$evidence_dir/source-index.tsv"
backup="$evidence_dir/source-index.pre-msys2-provenance-correction.tsv"
candidate="$evidence_dir/source-index.msys2-correction.tmp"
for path in "$verification" "$index"; do
  [ -f "$path" ] || { echo "Missing: $path" >&2; exit 2; }
done
for path in "$backup" "$candidate"; do
  [ ! -e "$path" ] || { echo "Refusing to overwrite: $path" >&2; exit 2; }
done

count=0
while IFS=$'\t' read -r package version url expected_sha upstream_url upstream_sha status notes; do
  [ "$package" = package ] && continue
  [ "$status" = MSYS2_SOURCE_PACKAGE_VERIFIED ] || continue
  case "$url" in https://repo.msys2.org/mingw/sources/*.src.tar.zst) ;; *) echo "Bad MSYS2 URL: $url" >&2; exit 1 ;; esac
  [ "${#expected_sha}" -eq 64 ] && [[ "$expected_sha" =~ ^[0-9a-f]+$ ]] || {
    echo "Bad MSYS2 SHA-256: $package" >&2; exit 1;
  }
  archive="$evidence_dir/source-packages/${package}-${version}.src.tar.zst"
  [ -f "$archive" ] || { echo "Missing source archive: $archive" >&2; exit 1; }
  actual_sha=$(sha256sum "$archive" | awk '{print $1}')
  [ "$actual_sha" = "$expected_sha" ] || { echo "Source archive hash mismatch: $package" >&2; exit 1; }
  if ! awk -F '\t' -v p="$package" -v v="$version" \
    'NR>1 && $1==p && $2==v && $7=="VERIFIED" {n++} END {exit n!=1}' "$index"; then
    echo "Expected one already verified source-index row: $package $version" >&2
    exit 1
  fi
  count=$((count + 1))
done < "$verification"
[ "$count" -eq 21 ] || { echo "Expected 21 reviewed MSYS2 packages, found $count" >&2; exit 1; }

awk -F '\t' 'BEGIN {OFS="\t"}
  NR==FNR {if(NR>1 && $7=="MSYS2_SOURCE_PACKAGE_VERIFIED") {key=$1 FS $2; url[key]=$3; sha[key]=$4} next}
  NR==1 {print; next}
  {key=$1 FS $2; if(key in url) {$5=url[key]; $6=sha[key]} print}
' "$verification" "$index" > "$candidate"
cp "$index" "$backup"
mv "$candidate" "$index"
echo "Corrected $count MSYS2 source-index rows; previous index: $backup"
