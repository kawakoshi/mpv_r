#!/usr/bin/env bash
set -euo pipefail

# Run from an MSYS2 MINGW64 shell on Windows. This script deliberately keeps
# mpv source, the Meson build directory, and the portable runtime folder apart.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/../.." && pwd)

tag="${MPV_TAG:-v0.41.0}"
source_dir="${MPV_SOURCE_DIR:-/c/work/codex/repos/mpv-r-upstream-${tag}}"
build_dir="${MPV_BUILD_DIR:-${source_dir}/build-mpv-r-${tag}}"
portable_dir="${MPV_PORTABLE_DIR:-/c/work/codex/builds/mpv_r-${tag}-portable}"
test_file="${MPV_TEST_FILE:-}"
mingw_prefix="${MINGW_PREFIX:-/mingw64}"
evidence_dir="${WINDOWS_BUILD_EVIDENCE:-}"

if [ "${MSYSTEM:-}" != "MINGW64" ]; then
  echo "Run this script from an MSYS2 MINGW64 shell." >&2
  exit 1
fi

for tool in git meson ninja ldd; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "Required tool not found: $tool" >&2
    exit 1
  }
done

if [ ! -d "$source_dir/.git" ]; then
  mkdir -p "$(dirname "$source_dir")"
  git -c core.autocrlf=false clone --branch "$tag" --depth 1 \
    https://github.com/mpv-player/mpv.git "$source_dir"
  git -C "$source_dir" config core.autocrlf false
fi

cd "$source_dir"
git diff --quiet || {
  echo "mpv source has uncommitted changes: $source_dir" >&2
  exit 1
}
git diff --cached --quiet || {
  echo "mpv source has staged changes: $source_dir" >&2
  exit 1
}

actual_tag="$(git describe --tags --exact-match 2>/dev/null || true)"
if [ "$actual_tag" != "$tag" ]; then
  echo "Expected source tag $tag, found ${actual_tag:-no exact tag}." >&2
  exit 1
fi

if [ ! -d "$build_dir" ]; then
  meson setup "$build_dir" -Dlibmpv=true -Dprefix="$mingw_prefix"
else
  meson setup --reconfigure "$build_dir" -Dlibmpv=true -Dprefix="$mingw_prefix"
fi
meson compile -C "$build_dir"

for file in "$build_dir/mpv.exe" "$build_dir/mpv.com" "$build_dir/libmpv-2.dll"; do
  test -f "$file" || {
    echo "Expected build output not found: $file" >&2
    exit 1
  }
done

if [ -e "$portable_dir" ]; then
  echo "Portable output already exists: $portable_dir" >&2
  exit 1
fi
mkdir -p "$portable_dir"
cp "$build_dir/mpv.exe" "$build_dir/mpv.com" "$build_dir/libmpv-2.dll" "$portable_dir/"

# ldd lists the transitive MINGW64 dependencies. Windows system DLLs are not
# copied; they remain supplied by the supported Windows runtime.
while IFS= read -r dll; do
  cp "$dll" "$portable_dir/"
done < <(ldd "$build_dir/mpv.exe" | awk '/=> \/mingw64\// {print $3}' | sort -u)

# ggml loads CPU backends by scanning for ggml-cpu-*.dll at runtime, so ldd
# cannot discover them. Copy every CPU variant supplied by the exact installed
# ggml package; the loader scores them and chooses the best supported variant.
if [ -f "$portable_dir/ggml.dll" ]; then
  ggml_cpu_count=0
  for dll in "$mingw_prefix"/bin/ggml-cpu-*.dll; do
    [ -f "$dll" ] || continue
    cp "$dll" "$portable_dir/"
    ggml_cpu_count=$((ggml_cpu_count + 1))
  done
  if [ "$ggml_cpu_count" -eq 0 ]; then
    echo "ggml.dll is present but no ggml CPU backend DLLs were found." >&2
    exit 1
  fi
fi

find "$portable_dir" -maxdepth 1 -type f -printf '%f\n' | sort > "$portable_dir/FILELIST.txt"
PATH="$portable_dir:/c/Windows/System32" "$portable_dir/mpv.exe" --version

if [ -n "$test_file" ]; then
  PATH="$portable_dir:/c/Windows/System32" "$portable_dir/mpv.exe" \
    --no-config --no-audio --vo=null "$test_file"
fi

printf 'Portable runtime: %s\n' "$portable_dir"
printf 'Executable/DLL file count: '
find "$portable_dir" -maxdepth 1 -type f \( -iname '*.exe' -o -iname '*.dll' \) | wc -l
sha256sum "$portable_dir/mpv.exe" "$portable_dir/mpv.com" "$portable_dir/libmpv-2.dll"

if [ -n "$evidence_dir" ]; then
  MPV_SOURCE_ARCHIVE_URL="${MPV_SOURCE_ARCHIVE_URL:-}" \
  MPV_SOURCE_ARCHIVE_SHA256="${MPV_SOURCE_ARCHIVE_SHA256:-}" \
  "$root/packaging/tools/capture-windows-msys2-runtime-evidence.sh" \
    "$source_dir" "$build_dir" "$portable_dir" "$evidence_dir"
fi
