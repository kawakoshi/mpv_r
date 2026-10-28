#!/usr/bin/env bash
set -euo pipefail

# Assemble only the texts retained by the prior source and build correlation.
# This creates a reviewable staging collection; it does not change release
# manifests or overwrite the installed-license collection.
if [ "$#" -ne 1 ]; then echo "Usage: $0 windows-evidence-dir" >&2; exit 2; fi
evidence_dir=$1
classification_file="$evidence_dir/source-license-classification-v1.tsv"
correlation="$evidence_dir/source-license-build-correlation-v1.tsv"
source_report="$evidence_dir/source-license-extraction-v3.tsv"
git_report="$evidence_dir/source-license-git-extraction-v2.tsv"
suffix=${SOURCE_LICENSE_COLLECTION_SUFFIX:-v1}
case "$suffix" in *[!A-Za-z0-9._-]*) echo "Invalid output suffix: $suffix" >&2; exit 2 ;; esac
output_dir="$evidence_dir/source-verified-license-collection-$suffix"
report="$evidence_dir/source-verified-license-manifest-$suffix.tsv"
for file in "$classification_file" "$correlation" "$source_report" "$git_report"; do [ -f "$file" ] || { echo "Missing: $file" >&2; exit 2; }; done
[ ! -e "$output_dir" ] && [ ! -e "$report" ] || { echo "Refusing to overwrite source-license collection" >&2; exit 2; }
mkdir -p "$output_dir"
printf 'package\tversion\tsource_member\tcollection_path\tsha256\tdecision\n' > "$report"
retain() {
  local package=$1 version=$2 member=$3 path=$4 sha=$5 classification decision
  classification=$(awk -F '\t' -v p="$package" -v m="$member" 'NR>1 && $1==p && $3==m {print $5; exit}' "$classification_file")
  decision=$classification
  if [ "$classification" = RETAIN_PENDING_EMBEDDED_COMPONENT_REVIEW ]; then
    decision=$(awk -F '\t' -v p="$package" -v m="$member" 'NR>1 && $1==p && $3==m {print $4; exit}' "$correlation")
  fi
  case "$decision" in RETAIN_RUNTIME_PACKAGE_LICENSE|RETAIN_RUNTIME_COMPONENT_LICENSE) ;; *) return 0 ;; esac
  source="$evidence_dir/$path"
  [ -f "$source" ] || { echo "Extracted text missing: $source" >&2; exit 1; }
  destination="$output_dir/$package/${member//\//_}"
  mkdir -p "$(dirname "$destination")"
  cp "$source" "$destination"
  actual=$(sha256sum "$destination" | awk '{print $1}')
  [ "$actual" = "$sha" ] || { echo "Hash mismatch: $source" >&2; exit 1; }
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$package" "$version" "$member" "${destination#"$evidence_dir/"}" "$actual" "$decision" >> "$report"
}
while IFS=$'\t' read -r package version archive member path sha status; do
  [ "$package" = package ] && continue; [ "$status" = EXTRACTED_NEEDS_REVIEW ] || continue
  retain "$package" "$version" "$member" "$path" "$sha"
done < "$source_report"
while IFS=$'\t' read -r package version archive commit member path sha status; do
  [ "$package" = package ] && continue
  retain "$package" "$version" "$member" "$path" "$sha"
done < "$git_report"
echo "Wrote: $report"
