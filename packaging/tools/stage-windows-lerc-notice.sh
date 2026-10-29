#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
evidence_dir=$1
package=mingw-w64-x86_64-lerc
candidate="$evidence_dir/standard-license-candidates-v1.tsv"
manifest="$evidence_dir/license-manifest.tsv"
backup="$evidence_dir/license-manifest.pre-lerc-notice.tsv"
destination="$evidence_dir/licenses/$package/share/licenses/lerc/NOTICE"
for required in "$candidate" "$manifest"; do
  [ -f "$required" ] || { echo "Missing: $required" >&2; exit 2; }
done
[ ! -e "$backup" ] && [ ! -e "$destination" ] || { echo "Lerc NOTICE already staged or backup exists" >&2; exit 2; }

record=$(awk -F '\t' -v p="$package" '
  NR > 1 && $1 == p && $4 ~ /\/NOTICE$/ {
    print $5 "\t" $6
    count++
  }
  END {if (count != 1) exit 1}
' "$candidate") || { echo "Cannot identify unique Lerc NOTICE candidate" >&2; exit 1; }
source_path=${record%%$'\t'*}
expected_sha=${record#*$'\t'}
source="$evidence_dir/$source_path"
[ -f "$source" ] || { echo "Missing: $source" >&2; exit 1; }
actual_sha=$(sha256sum "$source")
actual_sha=${actual_sha%% *}
[ "$actual_sha" = "$expected_sha" ] || { echo "Lerc NOTICE hash mismatch" >&2; exit 1; }

awk -F '\t' -v p="$package" '
  NR > 1 && $1 == p {
    if ($3 != 1 || $4 != "COLLECTED") exit 1
    count++
  }
  END {if (count != 1) exit 1}
' "$manifest" || { echo "Unexpected Lerc license manifest state" >&2; exit 1; }

cp "$manifest" "$backup"
cp "$source" "$destination"
temp=$(mktemp)
trap 'rm -f "$temp"' EXIT
awk -F '\t' -v OFS='\t' -v p="$package" '
  NR > 1 && $1 == p {$3=2}
  {print}
' "$backup" > "$temp"
mv "$temp" "$manifest"
echo "Staged Lerc NOTICE: $destination"
echo "Updated license manifest; backup: $backup"
