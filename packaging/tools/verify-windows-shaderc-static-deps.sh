#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
evidence_dir=$1
collected="$evidence_dir/shaderc-static-build-dependencies-v1"
manifest="$collected/artifact-manifest.tsv"
output="$evidence_dir/shaderc-static-dependency-verification-v1"
[ -f "$manifest" ] && [ -f "$collected/shaderc.BUILDINFO" ] || { echo "Missing collected shaderc dependencies" >&2; exit 2; }
[ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 2; }

scratch=$(mktemp -d "$evidence_dir/.shaderc-static-verify.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/license-texts"
printf 'package\tbuildinfo_version\tmsys2_source_url\tmsys2_source_sha256\tupstream_url\tupstream_sha256\tmsys2_binary_url\tmsys2_binary_sha256\tlicense_path\tlicense_sha256\tstatus\n' > "$scratch/verification.tsv"

for record in \
  'glslang|16.2.0-3|16.2.0|3' \
  'spirv-tools|3~1.4.350.0-1|1.4.350.0|1' \
  'spirv-headers|2~1.4.350.0-1|1.4.350.0|1'; do
  IFS='|' read -r name binary_version source_version source_rel <<< "$record"
  package="mingw-w64-x86_64-$name"
  source_file="$collected/source-packages/mingw-w64-$name-$binary_version.src.tar.zst"
  binary_file="$collected/binary-packages/$package-$binary_version-any.pkg.tar.zst"
  [ -f "$source_file" ] && [ -f "$binary_file" ] || { echo "Missing archive: $package" >&2; exit 1; }
  grep -Fxq "installed = $package-$binary_version-any" "$collected/shaderc.BUILDINFO" || {
    echo "BUILDINFO mismatch: $package" >&2; exit 1;
  }
  for kind in SOURCE BINARY; do
    entry=$(awk -F '\t' -v p="$package" -v v="$binary_version" -v k="$kind" '
      NR>1 && $1==p && $2==v && $3==k {print $4 "\t" $5; count++}
      END {if (count!=1) exit 1}
    ' "$manifest") || { echo "Missing artifact manifest entry: $package $kind" >&2; exit 1; }
    case "$kind" in SOURCE) source_url=${entry%%$'\t'*}; expected_source_sha=${entry#*$'\t'} ;;
      BINARY) binary_url=${entry%%$'\t'*}; expected_binary_sha=${entry#*$'\t'} ;;
    esac
  done
  source_sha=$(sha256sum "$source_file"); source_sha=${source_sha%% *}
  binary_sha=$(sha256sum "$binary_file"); binary_sha=${binary_sha%% *}
  [ "$source_sha" = "$expected_source_sha" ] && [ "$binary_sha" = "$expected_binary_sha" ] || {
    echo "Archive SHA-256 mismatch: $package" >&2; exit 1;
  }
  srcinfo_member="mingw-w64-$name/.SRCINFO"
  tar -xOf "$source_file" "$srcinfo_member" > "$scratch/SRCINFO"
  grep -Fq "pkgbase = mingw-w64-$name" "$scratch/SRCINFO"
  grep -Fq "pkgver = $source_version" "$scratch/SRCINFO"
  grep -Fq "pkgrel = $source_rel" "$scratch/SRCINFO"
  upstream_url=$(awk -F ' = ' '/^[[:space:]]*source = https:/ {print $2; exit}' "$scratch/SRCINFO")
  upstream_sha=$(awk -F ' = ' '/^[[:space:]]*sha256sums = / {print $2; exit}' "$scratch/SRCINFO")
  upstream_name=${upstream_url##*/}
  upstream_member="mingw-w64-$name/$upstream_name"
  actual_upstream_sha=$(tar -xOf "$source_file" "$upstream_member" | sha256sum)
  actual_upstream_sha=${actual_upstream_sha%% *}
  [ "$actual_upstream_sha" = "$upstream_sha" ] || { echo "Upstream source SHA-256 mismatch: $package" >&2; exit 1; }

  tar -xOf "$binary_file" .PKGINFO > "$scratch/PKGINFO"
  grep -Fxq "pkgname = $package" "$scratch/PKGINFO"
  grep -Fxq "pkgver = $binary_version" "$scratch/PKGINFO"
  license_member=$(tar tf "$binary_file" | grep '^mingw64/share/licenses/' | grep -v '/$')
  [ "$(printf '%s\n' "$license_member" | wc -l | tr -d '[:space:]')" = 1 ] || {
    echo "Unexpected license file count: $package" >&2; exit 1;
  }
  license_output="$scratch/license-texts/$name/${license_member##*/}"
  mkdir -p "$(dirname "$license_output")"
  tar -xOf "$binary_file" "$license_member" > "$license_output"
  license_sha=$(sha256sum "$license_output"); license_sha=${license_sha%% *}
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tVERIFIED_EXACT_BUILD_INPUT\n' \
    "$package" "$binary_version" "$source_url" "$source_sha" "$upstream_url" "$upstream_sha" \
    "$binary_url" "$binary_sha" "license-texts/$name/${license_member##*/}" "$license_sha" >> "$scratch/verification.tsv"
done
cp "$collected/shaderc.BUILDINFO" "$scratch/"
mv "$scratch" "$output"
trap - EXIT
echo "Wrote: $output (three exact build-time source, binary, and license records)"
