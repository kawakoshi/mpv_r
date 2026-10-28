#!/usr/bin/env bash
set -euo pipefail

# Conservative first-pass classification. It never declares a text legally
# cleared; it records which texts must be retained, which require build-feature
# review, and which are confined to non-runtime source areas.
if [ "$#" -ne 1 ]; then echo "Usage: $0 windows-evidence-dir" >&2; exit 2; fi
evidence_dir=$1
source_report="$evidence_dir/source-license-extraction-v3.tsv"
git_report="$evidence_dir/source-license-git-extraction-v2.tsv"
output="$evidence_dir/source-license-classification-v1.tsv"
for file in "$source_report" "$git_report"; do [ -f "$file" ] || { echo "Missing: $file" >&2; exit 2; }; done
[ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 2; }
printf 'package\tversion\tsource_member\textracted_path\tclassification\trationale\n' > "$output"
classify() {
  local member=$1
  case "$member" in
    */test/*|*/tests/*|*/debian/*|*/cmake/*|*/doc/*)
      printf 'EXCLUDE_CANDIDATE_NON_RUNTIME\tSource-tree test, packaging, documentation, or CMake helper; confirm it is absent from the runtime build.\n' ;;
    */third_party/*|*/dynamicHDR/*|*/fmt-*/*|*/gsl/*|*/LICENSE-pffft|*/lib/accelerated/*|*/lib/crau/*|*/lib/inih/*)
      printf 'RETAIN_PENDING_EMBEDDED_COMPONENT_REVIEW\tEmbedded component; retain until the clean build configuration proves it is not compiled into the shipped binary.\n' ;;
    *)
      printf 'RETAIN_RUNTIME_PACKAGE_LICENSE\tTop-level license or notice for the shipped dependency; retain in the release license collection.\n' ;;
  esac
}
while IFS=$'\t' read -r package version archive_sha member path text_sha status; do
  [ "$package" = package ] && continue
  [ "$status" = EXTRACTED_NEEDS_REVIEW ] || continue
  printf '%s\t%s\t%s\t%s\t' "$package" "$version" "$member" "$path" >> "$output"
  classify "$member" >> "$output"
done < "$source_report"
while IFS=$'\t' read -r package version archive_sha commit member path text_sha status; do
  [ "$package" = package ] && continue
  printf '%s\t%s\t%s\t%s\t' "$package" "$version" "$member" "$path" >> "$output"
  classify "$member" >> "$output"
done < "$git_report"
echo "Wrote: $output"
