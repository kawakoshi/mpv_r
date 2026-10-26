#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 mpv-source-checkout meson-build-dir evidence-dir" >&2
  exit 2
fi

source_dir=$1
build_dir=$2
evidence_dir=$3

if [ ! -d "$source_dir/.git" ]; then
  echo "Not a Git checkout: $source_dir" >&2
  exit 2
fi
if [ ! -d "$build_dir" ]; then
  echo "Meson build directory not found: $build_dir" >&2
  exit 2
fi
if [ -e "$evidence_dir" ]; then
  echo "Evidence directory already exists: $evidence_dir" >&2
  exit 2
fi

for command in git meson brew sw_vers xcodebuild; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Required command not found: $command" >&2
    exit 2
  fi
done

mkdir -p "$evidence_dir"

{
  printf 'captured_at_utc='
  date -u +%Y-%m-%dT%H:%M:%SZ
  printf 'source_checkout=%s\n' "$source_dir"
  printf 'meson_build_dir=%s\n' "$build_dir"
  printf 'head_commit='
  git -C "$source_dir" rev-parse HEAD
  printf 'describe='
  git -C "$source_dir" describe --always --tags --dirty
  printf '\n[git status --porcelain=v1]\n'
  git -C "$source_dir" status --porcelain=v1 --untracked-files=all
  printf '\n[untracked files]\n'
  git -C "$source_dir" ls-files --others --exclude-standard
} > "$evidence_dir/mpv-source.txt"

git -C "$source_dir" diff --binary HEAD > "$evidence_dir/mpv-source.patch"

{
  printf '[sw_vers]\n'
  sw_vers
  printf '\n[uname -a]\n'
  uname -a
  printf '\n[xcodebuild -version]\n'
  xcodebuild -version
  printf '\n[brew --version]\n'
  brew --version
  printf '\n[brew config]\n'
  brew config
  printf '\n[meson --version]\n'
  meson --version
  printf '\n[ninja --version]\n'
  ninja --version 2>&1 || true
  printf '\n[pkgconf --version]\n'
  pkgconf --version 2>&1 || true
} > "$evidence_dir/build-environment.txt"

meson introspect "$build_dir" --buildoptions > "$evidence_dir/meson-buildoptions.json"
meson introspect "$build_dir" --dependencies > "$evidence_dir/meson-dependencies.json"

printf 'Captured macOS build inputs: %s\n' "$evidence_dir"
