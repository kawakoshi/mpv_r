#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 homebrew-license-collection output.tsv" >&2
  exit 2
fi

collection=$1
output=$2
manifest="$collection/formula-manifest.tsv"
manifests="$collection/bottle-manifests"
if [ ! -f "$manifest" ] || [ ! -d "$manifests" ]; then
  echo "Collection is incomplete: $collection" >&2
  exit 2
fi

printf 'formula\tversion\tdeclared_license\thomebrew_formula_url\tformula_revision\tbottle_manifest\tsource_status\n' > "$output"
tail -n +2 "$manifest" | while IFS=$'\t' read -r formula version keg_path license_files bottle; do
  file="$manifests/$bottle"
  if [ ! -f "$file" ]; then
    file="$manifests/$formula-$version.json"
  fi
  if [ ! -f "$file" ]; then
    printf '%s\t%s\tMISSING\tMISSING\tMISSING\t%s\tBLOCKED: bottle manifest unavailable\n' \
      "$formula" "$version" "$bottle" >> "$output"
    continue
  fi
  license=$(jq -r '.annotations["org.opencontainers.image.licenses"] // "MISSING"' "$file")
  url=$(jq -r '.annotations["org.opencontainers.image.source"] // "MISSING"' "$file")
  revision=$(printf '%s\n' "$url" | sed -n 's#.*homebrew-core/blob/\([^/]*\)/.*#\1#p')
  [ -n "$revision" ] || revision=MISSING
  printf '%s\t%s\t%s\t%s\t%s\t%s\tFormula revision fixed; archive URL and checksum must be extracted from this Formula\n' \
    "$formula" "$version" "$license" "$url" "$revision" "$bottle" >> "$output"
done

echo "Wrote: $output"
