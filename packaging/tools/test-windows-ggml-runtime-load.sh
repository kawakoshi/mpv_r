#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 portable-runtime-dir" >&2
  exit 2
fi

runtime_dir=$1
script_dir=$(cd "$(dirname "$0")" && pwd)
source_file="$script_dir/ggml-runtime-load-smoke.c"

for required in ggml.dll ggml-base.dll ggml-cpu-x64.dll; do
  if [ ! -f "$runtime_dir/$required" ]; then
    echo "Missing ggml runtime file: $runtime_dir/$required" >&2
    exit 1
  fi
done
command -v gcc >/dev/null || { echo "gcc is required for this smoke test." >&2; exit 1; }

scratch=$(mktemp -d)
cleanup() { rm -rf "$scratch"; }
trap cleanup EXIT

gcc "$source_file" -O2 -Wall -Wextra -o "$scratch/ggml-runtime-load-smoke.exe"
(
  cd "$runtime_dir"
  PATH="$runtime_dir:/c/Windows/System32" "$scratch/ggml-runtime-load-smoke.exe"
)
