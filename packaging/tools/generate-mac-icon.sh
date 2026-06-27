#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/../.." && pwd)

source_svg="$root/assets/icons/mpv_r-icon.svg"
preview_dir="$root/build/icon-preview"
iconset_dir="$root/build/mpv_r-icon.iconset"
preview_png="$root/assets/icons/mpv_r-icon-1024.png"
icon_file="$root/assets/icons/mpv_r-icon.icns"

if [ ! -f "$source_svg" ]; then
  echo "Icon source not found: $source_svg" >&2
  exit 1
fi

rm -rf "$preview_dir" "$iconset_dir"
mkdir -p "$preview_dir" "$iconset_dir"

qlmanage -t -s 1024 -o "$preview_dir" "$source_svg" >/dev/null
rendered_png=$(find "$preview_dir" -type f -name "*.png" -print -quit)

if [ -z "$rendered_png" ]; then
  echo "Could not render icon SVG: $source_svg" >&2
  exit 1
fi

cp "$rendered_png" "$preview_png"

make_icon_png() {
  size="$1"
  name="$2"
  sips -z "$size" "$size" "$preview_png" --out "$iconset_dir/$name" >/dev/null
}

make_icon_png 16 "icon_16x16.png"
make_icon_png 32 "icon_16x16@2x.png"
make_icon_png 32 "icon_32x32.png"
make_icon_png 64 "icon_32x32@2x.png"
make_icon_png 128 "icon_128x128.png"
make_icon_png 256 "icon_128x128@2x.png"
make_icon_png 256 "icon_256x256.png"
make_icon_png 512 "icon_256x256@2x.png"
make_icon_png 512 "icon_512x512.png"
make_icon_png 1024 "icon_512x512@2x.png"

iconutil -c icns "$iconset_dir" -o "$icon_file"

echo "Created: $preview_png"
echo "Created: $icon_file"
