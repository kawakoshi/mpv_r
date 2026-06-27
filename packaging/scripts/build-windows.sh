#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/../.." && pwd)

version="${VERSION:-v0.2.0}"
mpv_dir="${WINDOWS_MPV_DIR:-$root/../windows-research/extracted-20260519}"
package_name="mpv_r"
output_dir="$root/dist"
output_zip="$output_dir/mpv_r-windows-$version.zip"
work_dir=$(mktemp -d "$root/build/package-windows.XXXXXX")
package_dir="$work_dir/$package_name"
launcher_path="$work_dir/mpv_r.exe"

. "$script_dir/package-common.sh"

for required in "$mpv_dir/mpv.exe" "$mpv_dir/mpv.com" "$mpv_dir/d3dcompiler_43.dll" "$mpv_dir/mpv/fonts.conf"; do
  if [ ! -f "$required" ]; then
    echo "Windows mpv file not found: $required" >&2
    exit 1
  fi
done

mkdir -p "$package_dir/resources/mpv/mpv"
mkdir -p "$package_dir/resources/config"
mkdir -p "$output_dir"

GOCACHE="$root/build/go-cache" GOOS=windows GOARCH=amd64 go build \
  -ldflags "-H windowsgui" \
  -o "$launcher_path" \
  "$root/cmd/mpv-r-launcher"

cp "$launcher_path" "$package_dir/mpv_r.exe"
cp "$mpv_dir/mpv.exe" "$package_dir/resources/mpv/mpv.exe"
cp "$mpv_dir/mpv.com" "$package_dir/resources/mpv/mpv.com"
cp "$mpv_dir/d3dcompiler_43.dll" "$package_dir/resources/mpv/d3dcompiler_43.dll"
cp "$mpv_dir/mpv/fonts.conf" "$package_dir/resources/mpv/mpv/fonts.conf"
cp "$root/config/windows/mpv.conf" "$package_dir/resources/config/mpv.conf"
cp "$root/config/windows/input.conf" "$package_dir/resources/config/input.conf"
copy_common_documents "$root" "$package_dir"

(
  cd "$work_dir"
  zip -r -X "$output_zip" "$package_name" >/dev/null
)

shasum -a 256 "$output_zip"
echo "Created: $output_zip"
echo "Work dir: $work_dir"

