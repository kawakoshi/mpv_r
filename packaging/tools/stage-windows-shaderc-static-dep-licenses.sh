#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
evidence_dir=$1
package=mingw-w64-x86_64-shaderc
verification="$evidence_dir/shaderc-static-dependency-verification-v1/verification.tsv"
manifest="$evidence_dir/license-manifest.tsv"
backup="$evidence_dir/license-manifest.pre-shaderc-static-deps.tsv"
destination="$evidence_dir/licenses/$package/static-build-dependencies"
[ -f "$verification" ] && [ -f "$manifest" ] || { echo "Missing verification or license manifest" >&2; exit 2; }
[ ! -e "$backup" ] && [ ! -e "$destination" ] || { echo "Shaderc static licenses already staged or backup exists" >&2; exit 2; }

awk -F '\t' -v p="$package" '
  NR>1 && $1==p {if ($3!=1 || $4!="COLLECTED") exit 1; count++}
  END {if (count!=1) exit 1}
' "$manifest" || { echo "Unexpected shaderc license manifest state" >&2; exit 1; }

scratch=$(mktemp -d "$evidence_dir/.shaderc-license-stage.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
count=0
while IFS=$'\t' read -r dep version source_url source_sha upstream_url upstream_sha binary_url binary_sha path expected_sha status; do
  [ "$dep" = package ] && continue
  [ "$status" = VERIFIED_EXACT_BUILD_INPUT ] || { echo "Unverified dependency: $dep" >&2; exit 1; }
  case "$dep:$version" in
    mingw-w64-x86_64-glslang:16.2.0-3|mingw-w64-x86_64-spirv-tools:3~1.4.350.0-1|mingw-w64-x86_64-spirv-headers:2~1.4.350.0-1) ;;
    *) echo "Unexpected shaderc dependency: $dep $version" >&2; exit 1 ;;
  esac
  text_file="$evidence_dir/shaderc-static-dependency-verification-v1/$path"
  [ -f "$text_file" ] || { echo "Missing license text: $text_file" >&2; exit 1; }
  actual_sha=$(sha256sum "$text_file"); actual_sha=${actual_sha%% *}
  [ "$actual_sha" = "$expected_sha" ] || { echo "License text SHA mismatch: $dep" >&2; exit 1; }
  dep_name=${dep#mingw-w64-x86_64-}
  mkdir -p "$scratch/$dep_name"
  cp "$text_file" "$scratch/$dep_name/${path##*/}"
  count=$((count + 1))
done < "$verification"
[ "$count" -eq 3 ] || { echo "Unexpected static dependency count: $count" >&2; exit 1; }

cp "$manifest" "$backup"
mv "$scratch" "$destination"
trap - EXIT
temp=$(mktemp)
trap 'rm -f "$temp"' EXIT
awk -F '\t' -v OFS='\t' -v p="$package" 'NR>1 && $1==p {$3=4} {print}' "$backup" > "$temp"
mv "$temp" "$manifest"
echo "Staged three exact-version shaderc static dependency license texts: $destination"
echo "Updated license manifest; backup: $backup"
