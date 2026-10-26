#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 runtime-manifest.tsv output-directory" >&2
  exit 2
fi

manifest=$1
output_dir=$2
cache_dir="$HOME/Library/Caches/Homebrew/downloads"
if [ ! -f "$manifest" ]; then
  echo "Manifest not found: $manifest" >&2
  exit 2
fi
if [ -e "$output_dir" ]; then
  echo "Output already exists: $output_dir" >&2
  exit 2
fi

mkdir -p "$output_dir/licenses" "$output_dir/receipts" "$output_dir/bottle-manifests"
printf 'formula\tversion\tkeg_path\tlicense_files\tbottle_manifest\n' \
  > "$output_dir/formula-manifest.tsv"
rows=$(mktemp "${TMPDIR:-/tmp}/mpv-r-homebrew-kegs.XXXXXX")
trap 'rm -f "$rows"' EXIT

tail -n +2 "$manifest" | while IFS=$'\t' read -r _ _ formula version keg_file _ _; do
  [ "$formula" = 'mpv-player/mpv' ] && continue
  [ "$formula" = UNMAPPED ] && continue
  keg_dir=$(dirname "$(dirname "$(realpath "$keg_file")")")
  printf '%s\t%s\t%s\n' "$formula" "$version" "$keg_dir" >> "$rows"
done

sort -u "$rows" | while IFS=$'\t' read -r formula version keg_dir; do
      case "$keg_dir" in
        */Cellar/"$formula"/"$version") ;;
        *) echo "Keg path does not match manifest: $keg_dir" >&2; exit 1 ;;
      esac
      destination="$output_dir/licenses/$formula-$version"
      mkdir -p "$destination"
      license_files=$(find "$keg_dir" -type f \( -iname 'LICENSE*' -o -iname 'COPYING*' -o -iname 'NOTICE*' \) -print)
      if [ -z "$license_files" ]; then
        count=MISSING_LOCAL
      else
        while IFS= read -r license; do
          relative=${license#"$keg_dir/"}
          mkdir -p "$destination/$(dirname "$relative")"
          cp "$license" "$destination/$relative"
        done <<< "$license_files"
        count=$(printf '%s\n' "$license_files" | sed '/^$/d' | wc -l | tr -d ' ')
      fi
      cp "$keg_dir/INSTALL_RECEIPT.json" "$output_dir/receipts/$formula-$version.json"
      bottle=$(find "$cache_dir" -type f -name "*--$formula-$version.bottle_manifest.json" -print -quit 2>/dev/null || true)
      if [ -n "$bottle" ]; then
        cp "$bottle" "$output_dir/bottle-manifests/$formula-$version.json"
        bottle_record=$(basename "$bottle")
      else
        bottle_record=MISSING
      fi
      printf '%s\t%s\t%s\t%s\t%s\n' "$formula" "$version" "$keg_dir" "$count" "$bottle_record" \
        >> "$output_dir/formula-manifest.tsv"
    done

echo "Wrote license collection: $output_dir"
