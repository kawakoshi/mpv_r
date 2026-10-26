#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/../.." && pwd)

version="${VERSION:-v0.3.0}"
source_app="${MAC_SOURCE_APP:-}"
source_zip="${MAC_SOURCE_ZIP:-$root/../dist/mpv_r-mac-v0.1.0.zip}"
build_dmg="${BUILD_DMG:-0}"
license_evidence="${MAC_LICENSE_EVIDENCE:-}"
require_license_evidence="${REQUIRE_MAC_LICENSE_EVIDENCE:-0}"
package_name="mpv_r"
output_dir="$root/dist"
output_zip="$output_dir/mpv_r-mac-$version.zip"
output_dmg="$output_dir/mpv_r-mac-$version.dmg"
work_dir=$(mktemp -d "$root/build/package-mac.XXXXXX")
source_dir="$work_dir/source"
package_dir="$work_dir/$package_name"
dmg_dir="$work_dir/dmg"

. "$script_dir/package-common.sh"

if [ -z "$source_app" ] && [ ! -f "$source_zip" ]; then
  echo "Mac source zip not found: $source_zip" >&2
  exit 1
fi

if [ "$require_license_evidence" = "1" ] && [ -z "$license_evidence" ]; then
  echo "MAC_LICENSE_EVIDENCE is required for this Mac release" >&2
  exit 1
fi
if [ -n "$license_evidence" ] && [ ! -d "$license_evidence" ]; then
  echo "Mac license evidence directory not found: $license_evidence" >&2
  exit 1
fi
if [ -n "$license_evidence" ]; then
  for evidence_file in runtime-manifest.tsv linkage.txt; do
    if [ ! -f "$license_evidence/$evidence_file" ]; then
      echo "Missing Mac license evidence: $license_evidence/$evidence_file" >&2
      exit 1
    fi
  done
  if [ ! -d "$license_evidence/homebrew-license-collection/licenses" ] || \
     [ ! -f "$license_evidence/homebrew-license-collection/primary-source-index.tsv" ]; then
    echo "Mac license evidence needs collected licenses and primary-source-index.tsv" >&2
    exit 1
  fi
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
plutil -replace CFBundleDocumentTypes.1.CFBundleTypeExtensions -json '["mp4","mov","m4v","mkv","webm","avi","mpg","mpeg","ts","m2ts","mts"]' "$plist"
plutil -replace CFBundleDocumentTypes.1.CFBundleTypeMIMETypes -json '["video/mp4","video/quicktime","video/x-matroska","video/webm","video/x-msvideo","video/mpeg"]' "$plist"
if [ -f "$root/assets/icons/mpv_r-icon.icns" ]; then
  cp "$root/assets/icons/mpv_r-icon.icns" "$resources_dir/icon.icns"
fi
cp "$root/config/mac/mpv.conf" "$package_dir/resources/config/mpv.conf"
cp "$root/config/mac/input.conf" "$package_dir/resources/config/input.conf"
cp "$root/config/mac/mpv.conf" "$resources_dir/mpv.conf"
cp "$root/config/mac/input.conf" "$resources_dir/input.conf"
copy_common_documents "$root" "$package_dir"
copy_common_documents "$root" "$resources_dir"

if [ -n "$license_evidence" ]; then
  for target in "$package_dir" "$resources_dir"; do
    evidence_target="$target/documents/LICENSES/macos-runtime"
    mkdir -p "$evidence_target"
    cp "$license_evidence/runtime-manifest.tsv" "$evidence_target/"
    cp "$license_evidence/linkage.txt" "$evidence_target/"
    cp "$license_evidence/homebrew-license-collection/primary-source-index.tsv" "$evidence_target/"
    cp "$license_evidence/homebrew-license-collection/homebrew-formula-index.tsv" "$evidence_target/"
    cp -R "$license_evidence/homebrew-license-collection/licenses" "$evidence_target/"
  done
fi

codesign --force --deep --sign - "$package_dir/mpv_r.app" >/dev/null

(
  cd "$work_dir"
  zip -r -X "$output_zip" "$package_name" >/dev/null
)

if [ "$build_dmg" = "1" ]; then
  mkdir -p "$dmg_dir"
  cp -R "$package_dir/mpv_r.app" "$dmg_dir/mpv_r.app"
  ln -s /Applications "$dmg_dir/Applications"
  hdiutil create \
    -volname "mpv_r $version" \
    -srcfolder "$dmg_dir" \
    -ov \
    -format UDZO \
    "$output_dmg" >/dev/null
  shasum -a 256 "$output_dmg"
  echo "Created: $output_dmg"
fi

shasum -a 256 "$output_zip"
echo "Created: $output_zip"
echo "Work dir: $work_dir"
