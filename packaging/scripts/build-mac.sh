#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/../.." && pwd)

version="${VERSION:-v0.2.0}"
source_app="${MAC_SOURCE_APP:-}"
source_zip="${MAC_SOURCE_ZIP:-$root/../dist/mpv_r-mac-v0.1.0.zip}"
package_name="mpv_r"
output_dir="$root/dist"
output_zip="$output_dir/mpv_r-mac-$version.zip"
work_dir=$(mktemp -d "$root/build/package-mac.XXXXXX")
source_dir="$work_dir/source"
package_dir="$work_dir/$package_name"

. "$script_dir/package-common.sh"

if [ -z "$source_app" ] && [ ! -f "$source_zip" ]; then
  echo "Mac source zip not found: $source_zip" >&2
  exit 1
fi

mkdir -p "$source_dir"
mkdir -p "$package_dir/resources/config"
mkdir -p "$output_dir"

if [ -n "$source_app" ]; then
  if [ ! -d "$source_app" ]; then
    echo "Mac source app not found: $source_app" >&2
    exit 1
  fi
  app_path="$source_app"
else
  unzip -q "$source_zip" -d "$source_dir"

  app_path=$(find "$source_dir" -maxdepth 2 -type d -name "mpv_r.app" -print -quit)
  if [ -z "$app_path" ]; then
    echo "mpv_r.app not found in source zip: $source_zip" >&2
    exit 1
  fi
fi

cp -R "$app_path" "$package_dir/mpv_r.app"
plist="$package_dir/mpv_r.app/Contents/Info.plist"
resources_dir="$package_dir/mpv_r.app/Contents/Resources"
plutil -replace CFBundleDisplayName -string "mpv_r" "$plist"
plutil -replace CFBundleName -string "mpv_r" "$plist"
plutil -replace CFBundleIdentifier -string "io.mpv.mpv-r" "$plist"
plutil -replace CFBundleIconFile -string "icon" "$plist"
if plutil -extract CFBundleIconName raw "$plist" >/dev/null 2>&1; then
  plutil -remove CFBundleIconName "$plist"
fi
plutil -replace LSApplicationCategoryType -string "public.app-category.video" "$plist"
if [ -f "$root/assets/icons/mpv_r-icon.icns" ]; then
  cp "$root/assets/icons/mpv_r-icon.icns" "$resources_dir/icon.icns"
fi
cp "$root/config/mac/mpv.conf" "$package_dir/resources/config/mpv.conf"
cp "$root/config/mac/input.conf" "$package_dir/resources/config/input.conf"
cp "$root/config/mac/mpv.conf" "$resources_dir/mpv.conf"
cp "$root/config/mac/input.conf" "$resources_dir/input.conf"
copy_common_documents "$root" "$package_dir"

codesign --force --deep --sign - "$package_dir/mpv_r.app" >/dev/null

(
  cd "$work_dir"
  zip -r -X "$output_zip" "$package_name" >/dev/null
)

shasum -a 256 "$output_zip"
echo "Created: $output_zip"
echo "Work dir: $work_dir"
