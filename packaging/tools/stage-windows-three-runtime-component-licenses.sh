#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
e=$1
manifest="$e/license-manifest.tsv"
backup="$e/license-manifest.pre-three-runtime-component-licenses.tsv"
report="$e/three-runtime-component-license-staging-v1.tsv"
review="$e/remaining-license-candidate-review-v1.tsv"
triage="$e/remaining-nested-license-build-triage-v4.tsv"
for required in "$manifest" "$review" "$triage"; do
  [ -f "$required" ] || { echo "Missing: $required" >&2; exit 1; }
done
for output in "$backup" "$report"; do
  [ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 1; }
done

scratch=$(mktemp -d "$e/.three-runtime-licenses.XXXXXX")
cleanup() { rm -rf "$scratch"; }
trap cleanup EXIT
cat > "$scratch/items.tsv" <<'ROWS'
package	version	license_member	expected_sha256	old_count	new_count	destination	reason
mingw-w64-x86_64-libgme	0.6.5-2	libgme-0.6.5/gme/ext/LICENSE	8fb093f26ed0d78c8ca033bbec7063ac5b34c5d2475e6bd121d03ccfaaf2355f	1	2	share/licenses/libgme/ext/LICENSE	emu2413_source_is_listed_in_libgme_library_sources
mingw-w64-x86_64-rav1e	0.8.1-1	rav1e-0.8.1/ivf/LICENSE	5d3c397a3aeeecbc417962e4df8e8432af8219fda8a56ebe601a638a1e76c522	2	3	share/licenses/rav1e/ivf/LICENSE	ivf_is_enabled_by_the_default_binaries_feature_during_cargo_c_build
mingw-w64-x86_64-harfbuzz	14.2.1-1	harfbuzz-14.2.1/src/ms-use/COPYING	c2cfccb812fe482101a8f04597dfc5a9991a6b2748266c47ac91b6a5aae15383	1	2	share/licenses/harfbuzz/ms-use/COPYING	microsoft_use_data_generates_tables_used_by_the_library
ROWS

check_sha() {
  local actual
  actual=$(sha256sum "$1"); actual=${actual%% *}
  [ "$actual" = "$2" ] || { echo "SHA-256 mismatch: $1" >&2; exit 1; }
}
cp "$manifest" "$scratch/manifest.tsv"
printf 'package\tversion\tlicense_member\tsha256\tdestination\treason\tstatus\n' > "$scratch/report.tsv"

while IFS=$'\t' read -r package version member expected_sha old_count new_count destination reason; do
  [ "$package" = package ] && continue
  extracted=$(awk -F '\t' -v p="$package" -v v="$version" -v m="$member" -v h="$expected_sha" '
    NR > 1 && $1 == p && $2 == v && $4 == m {if ($6 != h || $7 != "NESTED_SOURCE_TEXT" || $8 != "NEEDS_CONTENT_AND_BUILD_REVIEW") exit 1; print $5; n++}
    END {if (n != 1) exit 1}' "$review")
  awk -F '\t' -v p="$package" -v v="$version" -v m="$member" -v h="$expected_sha" '
    NR > 1 && $1 == p && $2 == v && $3 == m {if ($4 != h || $5 != "BUILD_COMPONENT_REVIEW_PENDING") exit 1; n++}
    END {if (n != 1) exit 1}' "$triage"
  check_sha "$e/$extracted" "$expected_sha"
  [ ! -e "$e/licenses/$package/$destination" ] || { echo "Refusing to overwrite staged text: $destination" >&2; exit 1; }
  actual_count=$(find "$e/licenses/$package" -type f | wc -l | tr -d '[:space:]')
  [ "$actual_count" = "$old_count" ]
  awk -F '\t' -v p="$package" -v v="$version" -v c="$old_count" '
    NR > 1 && $1 == p && $2 == v {if ($3 != c || $4 != "COLLECTED") exit 1; n++} END {if (n != 1) exit 1}' "$scratch/manifest.tsv"
  mkdir -p "$scratch/staged/$package/$(dirname "$destination")"
  cp "$e/$extracted" "$scratch/staged/$package/$destination"
  check_sha "$scratch/staged/$package/$destination" "$expected_sha"
  awk -F '\t' -v OFS='\t' -v p="$package" -v v="$version" -v c="$new_count" '
    $1 == p && $2 == v {$3=c; n++} {print} END {if (n != 1) exit 1}' "$scratch/manifest.tsv" > "$scratch/manifest.next"
  mv "$scratch/manifest.next" "$scratch/manifest.tsv"
  printf '%s\t%s\t%s\t%s\t%s\t%s\tSTAGED\n' "$package" "$version" "$member" "$expected_sha" "$destination" "$reason" >> "$scratch/report.tsv"
done < "$scratch/items.tsv"

cp "$manifest" "$backup"
for package_dir in "$scratch/staged"/*; do
  package=$(basename "$package_dir")
  cp -a "$package_dir/." "$e/licenses/$package/"
done
mv "$scratch/manifest.tsv" "$manifest"
mv "$scratch/report.tsv" "$report"
echo "Staged three runtime-component license texts and updated the license manifest."
