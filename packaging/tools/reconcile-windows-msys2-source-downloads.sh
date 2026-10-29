#!/usr/bin/env bash
set -euo pipefail

# Rebuild a source-download manifest from the archives themselves.  This is
# deliberately non-destructive: interrupted concurrent downloads can leave a
# duplicate progress log, which must not become release evidence.
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi

evidence_dir=$1
packages_dir="$evidence_dir/source-packages"
source_index="$evidence_dir/source-index.tsv"
suffix=${MSYS2_RECONCILIATION_SUFFIX:-}
if [ -n "$suffix" ]; then
  case "$suffix" in *[!A-Za-z0-9._-]*) echo "Invalid output suffix: $suffix" >&2; exit 2 ;; esac
  output="$evidence_dir/msys2-source-package-downloads-reconciled-$suffix.tsv"
else
  output="$evidence_dir/msys2-source-package-downloads-reconciled.tsv"
fi

for command in awk sha256sum; do
  command -v "$command" >/dev/null 2>&1 || { echo "Required command not found: $command" >&2; exit 2; }
done
if [ ! -d "$packages_dir" ] || [ ! -f "$source_index" ]; then
  echo "Missing source-package archive directory or source index in: $evidence_dir" >&2
  exit 2
fi
if [ -e "$output" ]; then
  echo "Refusing to overwrite: $output" >&2
  exit 2
fi

printf 'package\tversion\tmsys2_source_package_url\tsha256\tstatus\tnotes\n' > "$output"
while IFS=$'\t' read -r package version homepage license source_url source_sha source_status; do
  [ "$package" = package ] && continue
  case "$source_url" in https://repo.msys2.org/mingw/sources/*.src.tar.zst) ;; *) continue ;; esac
  archive="$packages_dir/${package}-${version}.src.tar.zst"
  [ -f "$archive" ] || continue
  sha=$(sha256sum "$archive" | awk '{print $1}')
  printf '%s\t%s\t%s\t%s\tRECONCILED_FROM_ARCHIVE\tArchive exists and its SHA-256 was recalculated; compare with the independent verification record before release.\n' \
    "$package" "$version" "$source_url" "$sha" >> "$output"
done < "$source_index"

echo "Wrote: $output"
