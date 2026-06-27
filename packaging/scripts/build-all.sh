#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

"$script_dir/build-mac.sh"
"$script_dir/build-windows.sh"

