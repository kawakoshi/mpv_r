#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 mpv_r-windows-v0.3.0-corresponding-source.tar.zst" >&2
  exit 2
fi

archive=$1
bundle_name=mpv_r-windows-v0.3.0-corresponding-source

if [ ! -f "$archive" ]; then
  echo "Missing corresponding-source asset: $archive" >&2
  exit 1
fi

zstd -t "$archive"

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
tar --zstd -xf "$archive" -C "$stage"
bundle="$stage/$bundle_name"

for required in README.txt ASSET-INFO.txt SHA256SUMS \
  windows-build-evidence/source-index.tsv \
  windows-build-evidence/source-packages mpv-source project-source; do
  if [ ! -e "$bundle/$required" ]; then
    echo "Missing asset content: $required" >&2
    exit 1
  fi
done

(
  cd "$bundle"
  sha256sum -c SHA256SUMS > "$stage/sha256-check.log"
)

checked_files=$(wc -l < "$bundle/SHA256SUMS" | tr -d '[:space:]')
# sha256sum -c above exits nonzero under set -e if any file fails. Do not parse
# its localized success text, which differs across Windows/MSYS2 environments.
failed_checks=0
source_rows=$(awk 'END {print NR - 1}' "$bundle/windows-build-evidence/source-index.tsv")
verified_rows=$(awk -F '\t' 'NR > 1 && $7 == "VERIFIED" {count++} END {print count + 0}' \
  "$bundle/windows-build-evidence/source-index.tsv")
source_package_count=$(find "$bundle/windows-build-evidence/source-packages" \
  -maxdepth 1 -type f -name '*.src.tar.zst' | wc -l | tr -d '[:space:]')

info_value() {
  key=$1
  awk -F = -v key="$key" '$1 == key {sub(/^[^=]*=/, ""); print; found=1} END {exit !found}' \
    "$bundle/ASSET-INFO.txt"
}

info_source_rows=$(info_value source_index_rows)
info_verified_rows=$(info_value verified_source_index_rows)
info_source_package_count=$(info_value msys2_source_package_count)
mpv_commit=$(info_value mpv_commit)
mpv_sha=$(info_value mpv_source_sha256)
project_commit=$(info_value mpv_r_project_commit)

if [ "$failed_checks" != 0 ] || \
   [ "$source_rows" != 87 ] || [ "$verified_rows" != 87 ] || \
   [ "$source_package_count" != 86 ] || \
   [ "$info_source_rows" != "$source_rows" ] || \
   [ "$info_verified_rows" != "$verified_rows" ] || \
   [ "$info_source_package_count" != "$source_package_count" ]; then
  echo "Corresponding-source inventory verification failed." >&2
  echo "checked_files=$checked_files" >&2
  echo "failed_checks=$failed_checks" >&2
  echo "source_index_rows=$source_rows (asset-info=$info_source_rows expected=87)" >&2
  echo "verified_source_index_rows=$verified_rows (asset-info=$info_verified_rows expected=87)" >&2
  echo "msys2_source_package_count=$source_package_count (asset-info=$info_source_package_count expected=86)" >&2
  exit 1
fi

mpv_archive="$bundle/mpv-source/mpv-$mpv_commit.tar.gz"
project_archive="$bundle/project-source/mpv_r-$project_commit.tar.gz"
if [ ! -f "$mpv_archive" ] || [ ! -f "$project_archive" ]; then
  echo "Missing fixed mpv or mpv_r project source archive." >&2
  exit 1
fi

actual_mpv_sha=$(sha256sum "$mpv_archive")
actual_mpv_sha=${actual_mpv_sha%% *}
if [ "$actual_mpv_sha" != "$mpv_sha" ]; then
  echo "Bundled mpv source archive hash mismatch." >&2
  exit 1
fi

project_prefix=$(tar -tzf "$project_archive" | sed -n '1p')
if [ "$project_prefix" != "mpv_r-$project_commit/" ]; then
  echo "Unexpected mpv_r project source prefix: $project_prefix" >&2
  exit 1
fi

asset_sha=$(sha256sum "$archive")
asset_sha=${asset_sha%% *}
asset_bytes=$(wc -c < "$archive" | tr -d '[:space:]')

echo "Corresponding-source asset is complete: $archive"
echo "asset_sha256=$asset_sha"
echo "asset_bytes=$asset_bytes"
echo "checked_files=$checked_files"
echo "source_index_rows=$source_rows"
echo "verified_source_index_rows=$verified_rows"
echo "msys2_source_package_count=$source_package_count"
echo "mpv_commit=$mpv_commit"
echo "mpv_r_project_commit=$project_commit"
