#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
evidence_dir=$1
suffix=${NESTED_RUNTIME_STAGING_SUFFIX:-v1}
case "$suffix" in *[!A-Za-z0-9._-]*) echo "Invalid output suffix: $suffix" >&2; exit 2 ;; esac
if [ "$suffix" = v1 ]; then
  triage="$evidence_dir/remaining-nested-license-build-triage-v3.tsv"
  expected_count=5
else
  triage="$evidence_dir/remaining-nested-license-build-triage-v4.tsv"
  expected_count=6
fi
output="$evidence_dir/remaining-nested-runtime-staging-$suffix.tsv"
[ -f "$triage" ] && [ -d "$evidence_dir/licenses" ] || { echo "Missing triage or staged licenses" >&2; exit 2; }
[ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 2; }
temp=$(mktemp)
trap 'rm -f "$temp"' EXIT
printf 'package\tversion\tlicense_member\tsha256\tstaged_match_path\tstatus\n' > "$temp"
count=0
while IFS=$'\t' read -r package version member expected_sha decision evidence; do
  [ "$decision" = RUNTIME_COMPONENT_TEXT ] || continue
  match=
  while IFS= read -r -d '' file; do
    actual_sha=$(sha256sum "$file")
    actual_sha=${actual_sha%% *}
    if [ "$actual_sha" = "$expected_sha" ]; then
      match=${file#"$evidence_dir/"}
      break
    fi
  done < <(find "$evidence_dir/licenses/$package" -type f -print0)
  [ -n "$match" ] || { echo "Runtime component license text missing: $package $member" >&2; exit 1; }
  printf '%s\t%s\t%s\t%s\t%s\tEXACT_TEXT_STAGED\n' \
    "$package" "$version" "$member" "$expected_sha" "$match" >> "$temp"
  count=$((count + 1))
done < "$triage"
[ "$count" -eq "$expected_count" ] || { echo "Unexpected runtime component text count: $count" >&2; exit 1; }
mv "$temp" "$output"
echo "Wrote: $output ($count exact runtime component texts staged)"
