#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
evidence_dir=$1
package=mingw-w64-x86_64-pcre2
review="$evidence_dir/remaining-license-candidate-review-v1.tsv"
triage="$evidence_dir/remaining-nested-license-build-triage-v4.tsv"
manifest="$evidence_dir/license-manifest.tsv"
backup="$evidence_dir/license-manifest.pre-pcre2-sljit.tsv"
destination="$evidence_dir/licenses/$package/source-components/sljit/LICENSE"
for required in "$review" "$triage" "$manifest"; do
  [ -f "$required" ] || { echo "Missing: $required" >&2; exit 2; }
done
[ ! -e "$backup" ] && [ ! -e "$destination" ] || { echo "SLJIT license already staged or backup exists" >&2; exit 2; }

record=$(awk -F '\t' -v p="$package" '
  NR>1 && $1==p && $4 ~ /\/deps\/sljit\/LICENSE$/ {print $5 "\t" $6; count++}
  END {if (count!=1) exit 1}
' "$review") || { echo "Cannot identify unique SLJIT text" >&2; exit 1; }
source_path=${record%%$'\t'*}
expected_sha=${record#*$'\t'}
source="$evidence_dir/$source_path"
[ -f "$source" ] || { echo "Missing: $source" >&2; exit 1; }
actual_sha=$(sha256sum "$source")
actual_sha=${actual_sha%% *}
[ "$actual_sha" = "$expected_sha" ] || { echo "SLJIT text hash mismatch" >&2; exit 1; }
awk -F '\t' -v p="$package" '
  NR>1 && $1==p && $3 ~ /\/deps\/sljit\/LICENSE$/ && $5=="RUNTIME_COMPONENT_TEXT" {count++}
  END {if (count!=1) exit 1}
' "$triage" || { echo "SLJIT is not marked as a runtime component" >&2; exit 1; }
awk -F '\t' -v p="$package" '
  NR>1 && $1==p {if ($3!=2 || $4!="COLLECTED") exit 1; count++}
  END {if (count!=1) exit 1}
' "$manifest" || { echo "Unexpected PCRE2 license manifest state" >&2; exit 1; }

cp "$manifest" "$backup"
mkdir -p "$(dirname "$destination")"
cp "$source" "$destination"
temp=$(mktemp)
trap 'rm -f "$temp"' EXIT
awk -F '\t' -v OFS='\t' -v p="$package" 'NR>1 && $1==p {$3=3} {print}' "$backup" > "$temp"
mv "$temp" "$manifest"
echo "Staged SLJIT license: $destination"
echo "Updated license manifest; backup: $backup"
