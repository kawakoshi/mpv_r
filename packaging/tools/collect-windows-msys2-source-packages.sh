#!/usr/bin/env bash
set -euo pipefail

# Download the MSYS2 source packages listed in captured Windows build evidence.
# This collects immutable inputs for review; it deliberately does not mark a
# dependency as release-verified. A reviewer must inspect PKGBUILD, patches,
# the nested upstream archive and applicable license texts before doing that.
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 evidence-directory [mingw-package ...]" >&2
  exit 2
fi

evidence_dir=$1
shift
source_index="$evidence_dir/source-index.tsv"
output_dir="$evidence_dir/source-packages"
report="$evidence_dir/msys2-source-package-downloads.tsv"

for command in curl sha256sum tar; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "Required command not found: $command" >&2
    exit 2
  }
done
if [ ! -f "$source_index" ]; then
  echo "Missing source index: $source_index" >&2
  exit 2
fi
if [ -e "$report" ]; then
  echo "Refusing to overwrite existing report: $report" >&2
  exit 2
fi

mkdir -p "$output_dir"
printf 'package\tversion\tmsys2_source_package_url\tsha256\tstatus\tnotes\n' > "$report"

requested=" $* "
while IFS=$'\t' read -r package version homepage license source_url source_sha source_status; do
  [ "$package" = package ] && continue
  case "$source_url" in
    https://repo.msys2.org/mingw/sources/*.src.tar.zst) ;;
    *) continue ;;
  esac
  if [ "$#" -gt 0 ] && [[ "$requested" != *" $package "* ]]; then
    continue
  fi

  archive="$output_dir/${package}-${version}.src.tar.zst"
  if [ -e "$archive" ]; then
    echo "Refusing to overwrite existing source package: $archive" >&2
    exit 2
  fi
  curl --fail --location --retry 3 --output "$archive" "$source_url"
  sha=$(sha256sum "$archive" | awk '{print $1}')
  listing=$(tar -tf "$archive")
  if ! printf '%s\n' "$listing" | grep -Eq '(^|/)PKGBUILD$'; then
    echo "Downloaded archive lacks PKGBUILD: $archive" >&2
    exit 1
  fi
  if ! printf '%s\n' "$listing" | grep -Eq '(^|/)\.SRCINFO$'; then
    echo "Downloaded archive lacks .SRCINFO: $archive" >&2
    exit 1
  fi
  printf '%s\t%s\t%s\t%s\tDOWNLOADED_NEEDS_REVIEW\tContains PKGBUILD and .SRCINFO; inspect patches, nested source archives, checksums, and license texts before release verification.\n' \
    "$package" "$version" "$source_url" "$sha" >> "$report"
done < "$source_index"

if [ "$#" -gt 0 ]; then
  found=$(awk -F '\t' 'NR > 1 {print $1}' "$report" | wc -l | tr -d ' ')
  if [ "$found" -ne "$#" ]; then
    echo "Not every requested package was found in $source_index" >&2
    exit 1
  fi
fi

echo "Wrote: $report"
