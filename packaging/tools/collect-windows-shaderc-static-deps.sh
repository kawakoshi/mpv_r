#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
evidence_dir=$1
runtime="$evidence_dir/runtime-manifest.tsv"
shaderc_pkg=/var/cache/pacman/pkg/mingw-w64-x86_64-shaderc-2026.2-1-any.pkg.tar.zst
output="$evidence_dir/shaderc-static-build-dependencies-v1"
[ -f "$runtime" ] && [ -f "$shaderc_pkg" ] || { echo "Missing runtime manifest or cached shaderc package" >&2; exit 2; }
[ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 2; }

expected_dll_sha=$(awk -F '\t' '$1=="libshaderc_shared.dll" && $5=="mingw-w64-x86_64-shaderc" && $6=="2026.2-1" {print $2; count++} END {if (count!=1) exit 1}' "$runtime") || {
  echo "Cannot identify exact shaderc runtime" >&2; exit 1;
}
package_dll_sha=$(tar -xOf "$shaderc_pkg" mingw64/bin/libshaderc_shared.dll | sha256sum)
package_dll_sha=${package_dll_sha%% *}
[ "$package_dll_sha" = "$expected_dll_sha" ] || { echo "Cached shaderc package does not match shipped DLL" >&2; exit 1; }

scratch=$(mktemp -d "$evidence_dir/.shaderc-static-deps.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/source-packages" "$scratch/binary-packages"
tar -xOf "$shaderc_pkg" .BUILDINFO > "$scratch/shaderc.BUILDINFO"
for record in \
  'glslang|16.2.0-3' \
  'spirv-tools|3~1.4.350.0-1' \
  'spirv-headers|2~1.4.350.0-1'; do
  name=${record%%|*}
  version=${record#*|}
  grep -Fxq "installed = mingw-w64-x86_64-$name-$version-any" "$scratch/shaderc.BUILDINFO" || {
    echo "shaderc BUILDINFO does not pin: $name $version" >&2; exit 1;
  }
done

printf 'package\tversion\tartifact_kind\turl\tsha256\n' > "$scratch/artifact-manifest.tsv"
for record in \
  'glslang|16.2.0-3' \
  'spirv-tools|3~1.4.350.0-1' \
  'spirv-headers|2~1.4.350.0-1'; do
  name=${record%%|*}
  version=${record#*|}
  source_name="mingw-w64-$name-$version.src.tar.zst"
  binary_name="mingw-w64-x86_64-$name-$version-any.pkg.tar.zst"
  source_url="https://repo.msys2.org/mingw/sources/$source_name"
  binary_url="https://repo.msys2.org/mingw/mingw64/$binary_name"
  curl -fL --retry 3 --connect-timeout 20 -o "$scratch/source-packages/$source_name" "$source_url"
  curl -fL --retry 3 --connect-timeout 20 -o "$scratch/binary-packages/$binary_name" "$binary_url"
  for row in "SOURCE|$source_url|$scratch/source-packages/$source_name" \
             "BINARY|$binary_url|$scratch/binary-packages/$binary_name"; do
    kind=${row%%|*}; rest=${row#*|}
    url=${rest%%|*}; path=${rest#*|}
    sha=$(sha256sum "$path"); sha=${sha%% *}
    printf 'mingw-w64-x86_64-%s\t%s\t%s\t%s\t%s\n' "$name" "$version" "$kind" "$url" "$sha" >> "$scratch/artifact-manifest.tsv"
  done
done
sha256sum "$shaderc_pkg" > "$scratch/shaderc-package.sha256"
cp "$shaderc_pkg" "$scratch/"
printf '%s\n' "$expected_dll_sha" > "$scratch/shipped-shaderc-dll.sha256"
mv "$scratch" "$output"
trap - EXIT
echo "Wrote: $output (three build-time dependencies, exact source and binary packages)"
