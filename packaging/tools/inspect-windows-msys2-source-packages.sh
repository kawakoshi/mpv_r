#!/usr/bin/env bash
set -euo pipefail

# Produce a review inventory from source packages already downloaded by
# collect-windows-msys2-source-packages.sh. This is evidence preparation, not
# license clearance: the result always requires human review.
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 evidence-directory" >&2
  exit 2
fi

evidence_dir=$1
downloads="$evidence_dir/msys2-source-package-downloads.tsv"
packages_dir="$evidence_dir/source-packages"
recipes_dir="$evidence_dir/source-package-recipes"
report="$evidence_dir/msys2-source-package-inspection.tsv"

for command in awk grep sha256sum tar; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "Required command not found: $command" >&2
    exit 2
  }
done
if [ ! -f "$downloads" ] || [ ! -d "$packages_dir" ]; then
  echo "Missing downloaded source-package evidence in: $evidence_dir" >&2
  exit 2
fi
if [ -e "$report" ] || [ -e "$recipes_dir" ]; then
  echo "Refusing to overwrite existing inspection evidence in: $evidence_dir" >&2
  exit 2
fi

mkdir -p "$recipes_dir"
printf 'package\tversion\tarchive_sha256\tpkgbuild_license\tpatch_count\tnested_source_archives\touter_license_candidates\tstatus\n' > "$report"

while IFS=$'\t' read -r package version source_url expected_sha download_status notes; do
  [ "$package" = package ] && continue
  archive="$packages_dir/${package}-${version}.src.tar.zst"
  if [ ! -f "$archive" ]; then
    echo "Downloaded archive missing: $archive" >&2
    exit 1
  fi
  actual_sha=$(sha256sum "$archive" | awk '{print $1}')
  if [ "$actual_sha" != "$expected_sha" ]; then
    echo "Downloaded archive hash does not match its manifest: $archive" >&2
    exit 1
  fi
  pkgbuild_path=$(tar -tf "$archive" | grep -E '/PKGBUILD$' | head -n 1 || true)
  [ -n "$pkgbuild_path" ] || {
    echo "PKGBUILD missing from: $archive" >&2
    exit 1
  }
  recipe_dir="$recipes_dir/$package"
  mkdir -p "$recipe_dir"
  tar -xOf "$archive" "$pkgbuild_path" > "$recipe_dir/PKGBUILD"
  tar -tf "$archive" > "$recipe_dir/archive-file-list.txt"

  pkgbuild_license=$(grep -E '^license=' "$recipe_dir/PKGBUILD" | tr '\n' ' ' | sed 's/[[:space:]]*$//' || true)
  [ -n "$pkgbuild_license" ] || pkgbuild_license=MISSING
  patch_count=$(grep -Ec '\.patch$' "$recipe_dir/archive-file-list.txt" || true)
  nested_sources=$(grep -E '\.(tar\.(gz|xz|bz2)|zip|7z)$' "$recipe_dir/archive-file-list.txt" | tr '\n' ';' | sed 's/;$//' || true)
  [ -n "$nested_sources" ] || nested_sources=NONE
  outer_licenses=$(grep -Ei '(^|/)(copying|license|copyright)(\.[^/]+)?$' "$recipe_dir/archive-file-list.txt" | tr '\n' ';' | sed 's/;$//' || true)
  [ -n "$outer_licenses" ] || outer_licenses=NONE
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\tMECHANICAL_INSPECTION_NEEDS_LICENSE_REVIEW\n' \
    "$package" "$version" "$actual_sha" "$pkgbuild_license" "$patch_count" "$nested_sources" "$outer_licenses" \
    >> "$report"
done < "$downloads"

echo "Wrote: $report"
