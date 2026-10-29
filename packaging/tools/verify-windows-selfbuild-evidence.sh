#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi

evidence_dir=$1
for required in runtime-manifest.tsv license-manifest.tsv source-index.tsv \
  mpv-source.txt mpv-source.patch build-environment.txt meson-buildoptions.json \
  meson-dependencies.json ldd licenses package-metadata; do
  if [ ! -e "$evidence_dir/$required" ]; then
    echo "Missing Windows release evidence: $evidence_dir/$required" >&2
    exit 1
  fi
done

if grep -q '^describe=.*-dirty$' "$evidence_dir/mpv-source.txt"; then
  echo "A dirty mpv source checkout blocks release; rebuild from a clean committed source." >&2
  exit 1
fi

if awk -F '\t' 'NR > 1 && $9 != "SOURCE_BUILD" && $9 != "MSYS2_PACKAGE_IDENTIFIED" {print; bad=1} END {exit bad}' \
  "$evidence_dir/runtime-manifest.tsv"; then :; else
  echo "Unidentified runtime files block release." >&2
  exit 1
fi
if awk -F '\t' 'NR > 1 && $4 != "COLLECTED" {print; bad=1} END {exit bad}' \
  "$evidence_dir/license-manifest.tsv"; then :; else
  echo "Missing installed license texts block release." >&2
  exit 1
fi
if awk -F '\t' 'NR > 1 && $1 == "libshaderc_shared.dll" && $5 == "mingw-w64-x86_64-shaderc" {found=1} END {exit !found}' \
  "$evidence_dir/runtime-manifest.tsv"; then
  bash "$(dirname "$0")/check-windows-shaderc-static-deps.sh" "$evidence_dir"
fi
if awk -F '\t' 'NR > 1 && ($5 == "MISSING" || $6 == "MISSING" || $7 != "VERIFIED") {print; bad=1} END {exit bad}' \
  "$evidence_dir/source-index.tsv"; then :; else
  echo "Unverified corresponding-source records block release." >&2
  exit 1
fi
if awk -F '\t' 'NR > 1 && $1 ~ /^mingw-w64-/ && \
  ($5 !~ /^https:\/\/repo\.msys2\.org\/mingw\/sources\/.*\.src\.tar\.zst$/ || \
   length($6) != 64 || $6 !~ /^[0-9a-f]+$/) {print; bad=1} END {exit bad}' \
  "$evidence_dir/source-index.tsv"; then :; else
  echo "MSYS2 dependencies must reference the patched MSYS2 source package and its SHA-256." >&2
  exit 1
fi

if [ ! -d "$evidence_dir/source-packages" ]; then
  echo "Missing MSYS2 source-package archives: $evidence_dir/source-packages" >&2
  exit 1
fi
while IFS=$'\t' read -r package version homepage license source_url expected_sha status; do
  [ "$package" = package ] && continue
  case "$package" in mingw-w64-*) ;; *) continue ;; esac
  recorded_license_count=$(awk -F '\t' -v p="$package" -v v="$version" '
    NR > 1 && $1 == p && $2 == v && $4 == "COLLECTED" {print $3; count++}
    END {if (count != 1) exit 1}
  ' "$evidence_dir/license-manifest.tsv") || {
    echo "Missing or duplicate license manifest entry: $package $version" >&2
    exit 1
  }
  actual_license_count=$(find "$evidence_dir/licenses/$package" -type f | wc -l | tr -d '[:space:]')
  if [ "$actual_license_count" != "$recorded_license_count" ]; then
    echo "Staged license count mismatch: $package $version" >&2
    exit 1
  fi
  archive="$evidence_dir/source-packages/${package}-${version}.src.tar.zst"
  if [ ! -f "$archive" ]; then
    echo "Missing MSYS2 source-package archive: $archive" >&2
    exit 1
  fi
  actual_sha=$(sha256sum "$archive")
  actual_sha=${actual_sha%% *}
  if [ "$actual_sha" != "$expected_sha" ]; then
    echo "MSYS2 source-package SHA-256 mismatch: $package $version" >&2
    exit 1
  fi
done < "$evidence_dir/source-index.tsv"

echo "Windows self-build evidence is complete: $evidence_dir"
