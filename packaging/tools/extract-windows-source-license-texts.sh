#!/usr/bin/env bash
set -euo pipefail

# Extract candidate license texts from already-verified MSYS2 source archives.
# This is deliberately evidence preparation only: it does not alter either
# license-manifest.tsv or source-index.tsv.  A reviewer must associate each
# extracted text with the shipped runtime package before changing release state.
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 windows-evidence-dir source-package-verification.tsv" >&2
  exit 2
fi

evidence_dir=$1
verification=$2
packages_dir="$evidence_dir/source-packages"
suffix=${SOURCE_LICENSE_EXTRACTION_SUFFIX:-}
if [ -n "$suffix" ]; then
  case "$suffix" in *[!A-Za-z0-9._-]*) echo "Invalid output suffix: $suffix" >&2; exit 2 ;; esac
  output_dir="$evidence_dir/licenses-from-verified-sources-$suffix"
  report="$evidence_dir/source-license-extraction-$suffix.tsv"
else
  output_dir="$evidence_dir/licenses-from-verified-sources"
  report="$evidence_dir/source-license-extraction.tsv"
fi

for command in awk find git mktemp sha256sum tar; do
  command -v "$command" >/dev/null 2>&1 || { echo "Required command not found: $command" >&2; exit 2; }
done
for file in "$evidence_dir/source-index.tsv" "$evidence_dir/license-manifest.tsv" "$verification"; do
  [ -f "$file" ] || { echo "Missing required file: $file" >&2; exit 2; }
done
[ -d "$packages_dir" ] || { echo "Missing source-package directory: $packages_dir" >&2; exit 2; }
if [ -e "$output_dir" ] || [ -e "$report" ]; then
  echo "Refusing to overwrite existing extraction evidence in: $evidence_dir" >&2
  exit 2
fi

cleanup() { rm -rf "$work_dir"; }
work_dir=$(mktemp -d)
trap cleanup EXIT
mkdir -p "$output_dir"
printf 'package\tversion\tsource_archive_sha256\tsource_member\textracted_path\textracted_sha256\tstatus\n' > "$report"

while IFS=$'\t' read -r package version source_url source_sha upstream_url upstream_sha status notes; do
  [ "$package" = package ] && continue
  [ "$status" = MSYS2_SOURCE_PACKAGE_VERIFIED ] || continue
  if ! awk -F '\t' -v p="$package" -v v="$version" \
    'NR > 1 && $1 == p && $2 == v {found=1} END {exit !found}' "$evidence_dir/source-index.tsv"; then
    continue
  fi
  # Packages whose installed license text was already collected need no source
  # fallback.  The verifier's MISSING_LOCAL_LICENSE rows are the only scope.
  if ! awk -F '\t' -v p="$package" -v v="$version" \
    'NR > 1 && $1 == p && $2 == v && $4 == "MISSING_LOCAL_LICENSE" {found=1} END {exit !found}' "$evidence_dir/license-manifest.tsv"; then
    continue
  fi
  archive="$packages_dir/${package}-${version}.src.tar.zst"
  [ -f "$archive" ] || { echo "Missing verified source archive: $archive" >&2; exit 1; }
  actual_sha=$(sha256sum "$archive" | awk '{print $1}')
  [ "$actual_sha" = "$source_sha" ] || { echo "Archive SHA mismatch: $archive" >&2; exit 1; }

  package_work="$work_dir/$package"
  mkdir -p "$package_work"
  tar -xf "$archive" -C "$package_work"
  # The MSYS2 source packages retain their upstream tarballs. Extract one level
  # so their own COPYING/LICENSE files become reviewable evidence.
  while IFS= read -r nested; do
    nested_dir="$package_work/nested/$(sha256sum "$nested" | awk '{print $1}')"
    mkdir -p "$nested_dir"
    tar -xf "$nested" -C "$nested_dir" 2>/dev/null || true
  done < <(find "$package_work" -type f \( -iname '*.tar.gz' -o -iname '*.tar.xz' -o -iname '*.tar.bz2' -o -iname '*.zip' \))

  count=0
  while IFS= read -r candidate; do
    relative=${candidate#"$package_work/"}
    destination="$output_dir/$package/$relative"
    mkdir -p "$(dirname "$destination")"
    cp "$candidate" "$destination"
    text_sha=$(sha256sum "$destination" | awk '{print $1}')
    printf '%s\t%s\t%s\t%s\t%s\t%s\tEXTRACTED_NEEDS_REVIEW\n' \
      "$package" "$version" "$actual_sha" "$relative" "${destination#"$evidence_dir/"}" "$text_sha" >> "$report"
    count=$((count + 1))
  done < <(find "$package_work" -type f \( -iname 'copying*' -o -iname 'license*' -o -iname 'copyright*' -o -iname 'notice*' \) | sort)
  [ "$count" -gt 0 ] || printf '%s\t%s\t%s\t-\t-\t-\tNO_TEXT_EXTRACTED_NEEDS_MANUAL_REVIEW\n' \
    "$package" "$version" "$actual_sha" >> "$report"
done < "$verification"

echo "Wrote: $report"
