#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
evidence_dir=$1
runtime="$evidence_dir/runtime-manifest.tsv"
package=mingw-w64-x86_64-shaderc
shaderc_pkg="$evidence_dir/shaderc-static-build-dependencies-v1/mingw-w64-x86_64-shaderc-2026.2-1-any.pkg.tar.zst"
collected="$evidence_dir/shaderc-static-build-dependencies-v1"
verification="$evidence_dir/shaderc-static-dependency-verification-v1/verification.tsv"

expected_dll_sha=$(awk -F '\t' '$1=="libshaderc_shared.dll" && $5=="mingw-w64-x86_64-shaderc" && $6=="2026.2-1" {print $2; count++} END {if (count!=1) exit 1}' "$runtime") || {
  echo "Cannot identify exact shaderc DLL in runtime manifest" >&2; exit 1;
}
for required in "$shaderc_pkg" "$collected/shaderc.BUILDINFO" "$collected/shaderc-package.sha256" "$verification"; do
  [ -f "$required" ] || { echo "Missing shaderc static-dependency evidence: $required" >&2; exit 1; }
done
expected_pkg_sha=$(awk 'NR==1 {print $1}' "$collected/shaderc-package.sha256")
actual_pkg_sha=$(sha256sum "$shaderc_pkg"); actual_pkg_sha=${actual_pkg_sha%% *}
[ "$expected_pkg_sha" = "$actual_pkg_sha" ] || { echo "shaderc binary package SHA mismatch" >&2; exit 1; }
actual_dll_sha=$(tar -xOf "$shaderc_pkg" mingw64/bin/libshaderc_shared.dll | sha256sum)
actual_dll_sha=${actual_dll_sha%% *}
[ "$actual_dll_sha" = "$expected_dll_sha" ] || { echo "shaderc DLL SHA mismatch" >&2; exit 1; }
actual_buildinfo_sha=$(tar -xOf "$shaderc_pkg" .BUILDINFO | sha256sum)
actual_buildinfo_sha=${actual_buildinfo_sha%% *}
stored_buildinfo_sha=$(sha256sum "$collected/shaderc.BUILDINFO")
stored_buildinfo_sha=${stored_buildinfo_sha%% *}
[ "$actual_buildinfo_sha" = "$stored_buildinfo_sha" ] || { echo "shaderc BUILDINFO mismatch" >&2; exit 1; }

count=0
declare -A seen=()
while IFS=$'\t' read -r dep version source_url source_sha upstream_url upstream_sha binary_url binary_sha path license_sha status; do
  [ "$dep" = package ] && continue
  [ "$status" = VERIFIED_EXACT_BUILD_INPUT ] || { echo "Unverified shaderc dependency: $dep" >&2; exit 1; }
  case "$dep:$version" in
    mingw-w64-x86_64-glslang:16.2.0-3|mingw-w64-x86_64-spirv-tools:3~1.4.350.0-1|mingw-w64-x86_64-spirv-headers:2~1.4.350.0-1) ;;
    *) echo "Unexpected shaderc dependency: $dep $version" >&2; exit 1 ;;
  esac
  [ -z "${seen[$dep]+x}" ] || { echo "Duplicate shaderc dependency: $dep" >&2; exit 1; }
  seen[$dep]=1
  grep -Fxq "installed = $dep-$version-any" "$collected/shaderc.BUILDINFO" || {
    echo "BUILDINFO version mismatch: $dep" >&2; exit 1;
  }
  source_archive="$collected/source-packages/${source_url##*/}"
  binary_archive="$collected/binary-packages/${binary_url##*/}"
  [ -f "$source_archive" ] && [ -f "$binary_archive" ] || { echo "Missing exact archive: $dep" >&2; exit 1; }
  actual_source_sha=$(sha256sum "$source_archive"); actual_source_sha=${actual_source_sha%% *}
  actual_binary_sha=$(sha256sum "$binary_archive"); actual_binary_sha=${actual_binary_sha%% *}
  [ "$actual_source_sha" = "$source_sha" ] && [ "$actual_binary_sha" = "$binary_sha" ] || {
    echo "Archive SHA mismatch: $dep" >&2; exit 1;
  }
  dep_name=${dep#mingw-w64-x86_64-}
  staged="$evidence_dir/licenses/$package/static-build-dependencies/$dep_name/${path##*/}"
  [ -f "$staged" ] || { echo "Missing staged static-dependency license: $dep" >&2; exit 1; }
  actual_license_sha=$(sha256sum "$staged"); actual_license_sha=${actual_license_sha%% *}
  [ "$actual_license_sha" = "$license_sha" ] || { echo "Static-dependency license SHA mismatch: $dep" >&2; exit 1; }
  count=$((count + 1))
done < "$verification"
[ "$count" -eq 3 ] || { echo "Unexpected static dependency count: $count" >&2; exit 1; }
echo "Exact shaderc build-time dependencies verified: $count"
