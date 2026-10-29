#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
evidence_dir=$1
review="$evidence_dir/remaining-license-candidate-review-v1.tsv"
staged="$evidence_dir/licenses"
suffix=${LICENSE_STAGING_COMPARISON_SUFFIX:-v1}
case "$suffix" in *[!A-Za-z0-9._-]*) echo "Invalid output suffix: $suffix" >&2; exit 2 ;; esac
report="$evidence_dir/remaining-root-license-staging-$suffix.tsv"
[ -f "$review" ] && [ -d "$staged" ] || { echo "Missing license review or staged license directory" >&2; exit 2; }
[ ! -e "$report" ] || { echo "Refusing to overwrite: $report" >&2; exit 2; }

hash_index=$(mktemp)
output=$(mktemp)
trap 'rm -f "$hash_index" "$output"' EXIT
while IFS= read -r -d '' file; do
  relative=${file#"$staged/"}
  package=${relative%%/*}
  sha=$(sha256sum "$file")
  sha=${sha%% *}
  printf '%s\t%s\t%s\n' "$package" "$sha" "${file#"$evidence_dir/"}" >> "$hash_index"
done < <(find "$staged" -type f -print0)

awk -F '\t' -v OFS='\t' '
  FILENAME == ARGV[1] {key=$1 SUBSEP $2; match_path[key]=$3; next}
  FNR == 1 {next}
  $7 != "PACKAGE_ROOT_TEXT" {next}
  {
    key=$1 SUBSEP $6
    if (key in match_path) status="EXACT_TEXT_ALREADY_STAGED"
    else status="ROOT_TEXT_NOT_IN_STAGED_LICENSES"
    print $1, $2, $4, $5, $6, (key in match_path ? match_path[key] : ""), status
    count++
  }
  END {
    if (count != 80) {print "Unexpected root candidate count: " count > "/dev/stderr"; exit 1}
  }' "$hash_index" "$review" > "$output"

printf 'package\tversion\tlicense_member\textracted_path\tsha256\tstaged_match_path\tstatus\n' > "$report"
cat "$output" >> "$report"
echo "Wrote: $report (80 root source texts compared with staged licenses)"
