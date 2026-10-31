#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 windows-evidence-dir mpv-source-archive output.tar.zst" >&2
  exit 2
fi

evidence_dir=$1
mpv_archive=$2
output=$3
root=$(cd "$(dirname "$0")/../.." && pwd)
bundle_name=mpv_r-windows-v0.3.0-corresponding-source

if [ -e "$output" ]; then
  echo "Refusing to overwrite existing output: $output" >&2
  exit 1
fi

bash "$root/packaging/tools/verify-windows-selfbuild-evidence.sh" "$evidence_dir"

read -r mpv_package mpv_commit mpv_homepage mpv_license mpv_url mpv_sha mpv_status < <(
  awk -F '\t' 'NR == 2 {print $1, $2, $3, $4, $5, $6, $7}' \
    "$evidence_dir/source-index.tsv"
)

if [ "$mpv_package" != "mpv-player/mpv" ] || [ "$mpv_status" != "VERIFIED" ]; then
  echo "The first source-index row is not the verified mpv source." >&2
  exit 1
fi

actual_mpv_sha=$(sha256sum "$mpv_archive")
actual_mpv_sha=${actual_mpv_sha%% *}
if [ "$actual_mpv_sha" != "$mpv_sha" ]; then
  echo "mpv source archive SHA-256 mismatch." >&2
  echo "Expected: $mpv_sha" >&2
  echo "Actual:   $actual_mpv_sha" >&2
  exit 1
fi

source_rows=$(awk 'END {print NR - 1}' "$evidence_dir/source-index.tsv")
verified_rows=$(awk -F '\t' 'NR > 1 && $7 == "VERIFIED" {count++} END {print count + 0}' \
  "$evidence_dir/source-index.tsv")
source_package_count=$(find "$evidence_dir/source-packages" -maxdepth 1 -type f \
  -name '*.src.tar.zst' | wc -l | tr -d '[:space:]')

if [ "$source_rows" != "$verified_rows" ] || [ "$source_package_count" != 86 ]; then
  echo "Unexpected source inventory: rows=$source_rows verified=$verified_rows packages=$source_package_count" >&2
  exit 1
fi

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
bundle="$stage/$bundle_name"
mkdir -p "$bundle/mpv-source" "$bundle/project-source"

cp -a "$evidence_dir" "$bundle/windows-build-evidence"
cp "$mpv_archive" "$bundle/mpv-source/mpv-$mpv_commit.tar.gz"

project_commit=$(git -C "$root" rev-parse HEAD)
origin_main_commit=$(git -C "$root" rev-parse refs/remotes/origin/main)
if [ "$project_commit" != "$origin_main_commit" ]; then
  echo "Refusing to archive a revision other than origin/main." >&2
  echo "HEAD:        $project_commit" >&2
  echo "origin/main: $origin_main_commit" >&2
  exit 1
fi
git -C "$root" archive --format=tar.gz \
  --prefix="mpv_r-$project_commit/" \
  --output="$bundle/project-source/mpv_r-$project_commit.tar.gz" HEAD

cat > "$bundle/README.txt" <<EOF
mpv_r Windows v0.3.0 corresponding source
==========================================

This archive accompanies mpv_r-windows-v0.3.0.zip.

Contents:

- windows-build-evidence/: the verified final Windows build evidence, including
  source-index.tsv, build records, package metadata, license evidence, and the
  exact 86 MSYS2 .src.tar.zst source packages used for the runtime dependencies.
- mpv-source/: the exact upstream mpv source archive identified and hashed by
  source-index.tsv.
- project-source/: a Git archive of the mpv_r project revision used to create
  this corresponding-source asset, including launcher and packaging sources.
- SHA256SUMS: SHA-256 for every other file in this archive.
- ASSET-INFO.txt: fixed source and project identifiers plus inventory counts.

The Windows application package itself is distributed separately. This archive
is source and build evidence; it is not an application installer.
EOF

cat > "$bundle/ASSET-INFO.txt" <<EOF
asset=$bundle_name.tar.zst
mpv_package=$mpv_package
mpv_commit=$mpv_commit
mpv_source_url=$mpv_url
mpv_source_sha256=$mpv_sha
mpv_declared_license=$mpv_license
mpv_r_project_commit=$project_commit
source_index_rows=$source_rows
verified_source_index_rows=$verified_rows
msys2_source_package_count=$source_package_count
EOF

(
  cd "$bundle"
  find . -type f ! -name SHA256SUMS -print0 \
    | sort -z \
    | xargs -0 sha256sum > SHA256SUMS
)

mkdir -p "$(dirname "$output")"
tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
  --zstd -cf "$output" -C "$stage" "$bundle_name"

sha256sum "$output"
du -h "$output"
