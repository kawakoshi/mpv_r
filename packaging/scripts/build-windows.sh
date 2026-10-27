#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/../.." && pwd)

version="${VERSION:-v0.2.0}"
mpv_dir="${WINDOWS_MPV_DIR:-$root/../windows-research/extracted-20260519}"
license_evidence="${WINDOWS_LICENSE_EVIDENCE:-}"
require_license_evidence="${REQUIRE_WINDOWS_LICENSE_EVIDENCE:-0}"
package_name="mpv_r"
output_dir="$root/dist"
output_zip="$output_dir/mpv_r-windows-$version.zip"
mkdir -p "$root/build"
work_dir=$(mktemp -d "$root/build/package-windows.XXXXXX")
package_dir="$work_dir/$package_name"
launcher_path="$work_dir/mpv_r.exe"
launcher_dir="$root/cmd/mpv-r-launcher"
resource_path="$launcher_dir/resource.syso"

. "$script_dir/package-common.sh"

run_goversioninfo() {
  if command -v goversioninfo >/dev/null 2>&1; then
    goversioninfo "$@"
  else
    go run github.com/josephspurrier/goversioninfo/cmd/goversioninfo@v1.7.0 "$@"
  fi
}

cleanup() {
  rm -f "$resource_path"
}

trap cleanup EXIT HUP INT TERM

for required in "$mpv_dir/mpv.exe"; do
  if [ ! -f "$required" ]; then
    echo "Windows mpv file not found: $required" >&2
    exit 1
  fi
done

if [ "$require_license_evidence" = "1" ] && [ -z "$license_evidence" ]; then
  echo "WINDOWS_LICENSE_EVIDENCE is required for this Windows release" >&2
  exit 1
fi
if [ -n "$license_evidence" ]; then
  if [ ! -d "$license_evidence" ]; then
    echo "Windows license evidence directory not found: $license_evidence" >&2
    exit 1
  fi
  "$root/packaging/tools/verify-windows-selfbuild-evidence.sh" "$license_evidence"
fi

mkdir -p "$package_dir/resources/mpv"
mkdir -p "$package_dir/resources/config"
mkdir -p "$output_dir"

rm -f "$resource_path"
if [ -f "$root/assets/icons/mpv_r-icon.ico" ]; then
  run_goversioninfo \
    -skip-versioninfo \
    -64 \
    -icon="$root/assets/icons/mpv_r-icon.ico" \
    -application-icon="$root/assets/icons/mpv_r-icon.ico" \
    -o="$resource_path"
fi

GOCACHE="$root/build/go-cache" GOOS=windows GOARCH=amd64 go build \
  -ldflags "-H windowsgui" \
  -o "$launcher_path" \
  "$root/cmd/mpv-r-launcher"

cp "$launcher_path" "$package_dir/mpv_r.exe"
runtime_count=0
for runtime_file in "$mpv_dir"/*.exe "$mpv_dir"/*.dll; do
  if [ -f "$runtime_file" ]; then
    cp "$runtime_file" "$package_dir/resources/mpv/"
    runtime_count=$((runtime_count + 1))
  fi
done
if [ "$runtime_count" -lt 2 ]; then
  echo "Windows runtime must contain mpv.exe and at least one DLL: $mpv_dir" >&2
  exit 1
fi
if [ -f "$mpv_dir/mpv/fonts.conf" ]; then
  mkdir -p "$package_dir/resources/mpv/mpv"
  cp "$mpv_dir/mpv/fonts.conf" "$package_dir/resources/mpv/mpv/fonts.conf"
fi
cp "$root/config/windows/mpv.conf" "$package_dir/resources/config/mpv.conf"
cp "$root/config/windows/input.conf" "$package_dir/resources/config/input.conf"
copy_common_documents "$root" "$package_dir"
cp "$root/docs/windows-preview-guide.md" "$package_dir/documents/windows-preview-guide.md"
cp "$root/translations_ja/windows-preview-guide_jp.md" \
  "$package_dir/documents/translations_ja/windows-preview-guide_jp.md"
if [ -n "$license_evidence" ]; then
  evidence_target="$package_dir/documents/LICENSES/windows-selfbuild"
  mkdir -p "$evidence_target"
  cp "$license_evidence/runtime-manifest.tsv" "$evidence_target/"
  cp "$license_evidence/license-manifest.tsv" "$evidence_target/"
  cp "$license_evidence/source-index.tsv" "$evidence_target/"
  cp "$license_evidence/mpv-source.txt" "$evidence_target/"
  cp "$license_evidence/mpv-source.patch" "$evidence_target/"
  cp "$license_evidence/build-environment.txt" "$evidence_target/"
  cp "$license_evidence/meson-buildoptions.json" "$evidence_target/"
  cp "$license_evidence/meson-dependencies.json" "$evidence_target/"
  cp -R "$license_evidence/licenses" "$evidence_target/"
  cp -R "$license_evidence/package-metadata" "$evidence_target/"
  cp -R "$license_evidence/ldd" "$evidence_target/"
  mkdir -p "$evidence_target/build-scripts"
  cp "$root/packaging/scripts/build-mpv-windows-msys2.sh" "$evidence_target/build-scripts/"
  cp "$root/packaging/scripts/build-windows.sh" "$evidence_target/build-scripts/"
  cp "$root/packaging/tools/capture-windows-msys2-runtime-evidence.sh" "$evidence_target/build-scripts/"
  cp "$root/packaging/tools/verify-windows-selfbuild-evidence.sh" "$evidence_target/build-scripts/"
fi
mkdir -p "$package_dir/tools"
cp "$root/packaging/windows/register-file-associations.ps1" \
  "$package_dir/tools/register-file-associations.ps1"
cp "$root/packaging/windows/register-file-associations.cmd" \
  "$package_dir/register-file-associations.cmd"
cp "$root/packaging/windows/create-desktop-shortcut.ps1" \
  "$package_dir/tools/create-desktop-shortcut.ps1"
cp "$root/packaging/windows/create-desktop-shortcut.cmd" \
  "$package_dir/create-desktop-shortcut.cmd"

if [ -n "$license_evidence" ]; then
  final_manifest="$package_dir/documents/LICENSES/windows-selfbuild/final-package-runtime-manifest.tsv"
  printf 'package_path\tsha256\tbytes\n' > "$final_manifest"
  find "$package_dir" -type f \( -iname '*.exe' -o -iname '*.com' -o -iname '*.dll' \) -print | sort | \
    while IFS= read -r runtime_file; do
      relative=${runtime_file#"$package_dir/"}
      sha=$(shasum -a 256 "$runtime_file" | awk '{print $1}')
      bytes=$(wc -c < "$runtime_file" | tr -d ' ')
      printf '%s\t%s\t%s\n' "$relative" "$sha" "$bytes" >> "$final_manifest"
    done
fi

if command -v zip >/dev/null 2>&1; then
  (
    cd "$work_dir"
    zip -r -X "$output_zip" "$package_name" >/dev/null
  )
elif command -v powershell.exe >/dev/null 2>&1; then
  package_dir_win=$(cygpath -w "$package_dir")
  output_zip_win=$(cygpath -w "$output_zip")
  powershell.exe -NoProfile -Command \
    "Compress-Archive -LiteralPath '$package_dir_win' -DestinationPath '$output_zip_win' -Force" \
    >/dev/null
else
  echo "Neither zip nor powershell.exe is available to create the package." >&2
  exit 1
fi

shasum -a 256 "$output_zip"
echo "Created: $output_zip"
echo "Work dir: $work_dir"
