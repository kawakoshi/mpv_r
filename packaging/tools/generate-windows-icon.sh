#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/../.." && pwd)

preview_png="$root/assets/icons/mpv_r-icon-1024.png"
work_dir="$root/build/windows-icon"
icon_file="$root/assets/icons/mpv_r-icon.ico"

if [ ! -f "$preview_png" ]; then
  "$script_dir/generate-mac-icon.sh" >/dev/null
fi

rm -rf "$work_dir"
mkdir -p "$work_dir"

for size in 16 24 32 48 64 128 256; do
  sips -z "$size" "$size" "$preview_png" --out "$work_dir/icon_${size}.png" >/dev/null
done

python3 "$script_dir/pngs-to-ico.py" \
  "$icon_file" \
  "$work_dir/icon_16.png" \
  "$work_dir/icon_24.png" \
  "$work_dir/icon_32.png" \
  "$work_dir/icon_48.png" \
  "$work_dir/icon_64.png" \
  "$work_dir/icon_128.png" \
  "$work_dir/icon_256.png"
