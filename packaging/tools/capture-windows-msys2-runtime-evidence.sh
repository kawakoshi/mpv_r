#!/usr/bin/env bash
set -euo pipefail

# Run from MSYS2 MINGW64 after the portable runtime has been assembled.
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 mpv-source-checkout meson-build-dir portable-runtime-dir evidence-dir" >&2
  exit 2
fi

source_dir=$1
build_dir=$2
runtime_dir=$3
evidence_dir=$4
mingw_prefix=${MINGW_PREFIX:-/mingw64}

if [ "${MSYSTEM:-}" != "MINGW64" ]; then
  echo "Run this script from an MSYS2 MINGW64 shell." >&2
  exit 2
fi
for command in git meson pacman ldd sha256sum; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "Required command not found: $command" >&2
    exit 2
  }
done
if [ ! -d "$source_dir/.git" ] || [ ! -d "$build_dir" ] || [ ! -d "$runtime_dir" ]; then
  echo "Source checkout, Meson build directory, or runtime directory is missing." >&2
  exit 2
fi
if [ -e "$evidence_dir" ]; then
  echo "Evidence directory already exists: $evidence_dir" >&2
  exit 2
fi

mkdir -p "$evidence_dir" "$evidence_dir/ldd" "$evidence_dir/package-metadata" \
  "$evidence_dir/licenses"

{
  printf 'captured_at_utc='
  date -u +%Y-%m-%dT%H:%M:%SZ
  printf 'source_checkout=%s\n' "$source_dir"
  printf 'head_commit='
  git -C "$source_dir" rev-parse HEAD
  printf 'describe='
  git -C "$source_dir" describe --always --tags --dirty
  printf '\n[git status --porcelain=v1]\n'
  git -C "$source_dir" status --porcelain=v1 --untracked-files=all
} > "$evidence_dir/mpv-source.txt"
git -C "$source_dir" diff --binary HEAD > "$evidence_dir/mpv-source.patch"

{
  printf '[uname -a]\n'
  uname -a
  printf '\n[MSYSTEM]\n%s\n' "${MSYSTEM:-UNSET}"
  printf '\n[MINGW_PREFIX]\n%s\n' "$mingw_prefix"
  printf '\n[pacman -V]\n'
  pacman -V
  printf '\n[pacman -Q]\n'
  pacman -Q
  printf '\n[cc --version]\n'
  cc --version
  printf '\n[meson --version]\n'
  meson --version
  printf '\n[ninja --version]\n'
  ninja --version 2>&1 || true
} > "$evidence_dir/build-environment.txt"

meson introspect "$build_dir" --buildoptions > "$evidence_dir/meson-buildoptions.json"
meson introspect "$build_dir" --dependencies > "$evidence_dir/meson-dependencies.json"

for executable in mpv.exe mpv.com libmpv-2.dll; do
  test -f "$runtime_dir/$executable" || {
    echo "Runtime file missing: $runtime_dir/$executable" >&2
    exit 2
  }
  ldd "$runtime_dir/$executable" > "$evidence_dir/ldd/$executable.txt"
done

printf 'runtime_file\tsha256\tbytes\torigin_path\towner_package\tpackage_version\tdeclared_license\tpackage_homepage\tstatus\n' \
  > "$evidence_dir/runtime-manifest.tsv"
declare -A packages=()
while IFS= read -r runtime_file; do
  name=$(basename "$runtime_file")
  sha=$(sha256sum "$runtime_file" | awk '{print $1}')
  bytes=$(wc -c < "$runtime_file" | tr -d ' ')
  case "$name" in
    mpv.exe|mpv.com|libmpv-2.dll)
      printf '%s\t%s\t%s\tSOURCE_BUILD\tPROJECT_BUILD\t%s\tGPL-2.0-or-later\thttps://github.com/mpv-player/mpv\tSOURCE_BUILD\n' \
        "$name" "$sha" "$bytes" "$(git -C "$source_dir" rev-parse HEAD)" \
        >> "$evidence_dir/runtime-manifest.tsv"
      ;;
    *)
      origin_path=$runtime_file
      package=$(LC_ALL=C pacman -Qqo "$origin_path" 2>/dev/null || true)
      if [ -z "$package" ] && [ -f "$mingw_prefix/bin/$name" ]; then
        origin_path="$mingw_prefix/bin/$name"
        package=$(LC_ALL=C pacman -Qqo "$origin_path" 2>/dev/null || true)
      fi
      if [ -z "$package" ]; then
        printf '%s\t%s\t%s\tMISSING\tMISSING\tMISSING\tMISSING\tMISSING\tUNOWNED_RUNTIME_FILE\n' \
          "$name" "$sha" "$bytes" >> "$evidence_dir/runtime-manifest.tsv"
        continue
      fi
      packages["$package"]=1
      package_version=$(pacman -Q "$package" | awk '{print $2}')
      package_info=$(LC_ALL=C pacman -Qi "$package")
      declared_license=$(printf '%s\n' "$package_info" | sed -n 's/^Licenses[[:space:]]*: //p' | head -n 1)
      homepage=$(printf '%s\n' "$package_info" | sed -n 's/^URL[[:space:]]*: //p' | head -n 1)
      [ -n "$declared_license" ] || declared_license=MISSING
      [ -n "$homepage" ] || homepage=MISSING
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tMSYS2_PACKAGE_IDENTIFIED\n' \
        "$name" "$sha" "$bytes" "$origin_path" "$package" "$package_version" "$declared_license" "$homepage" \
        >> "$evidence_dir/runtime-manifest.tsv"
      ;;
  esac
done < <(find "$runtime_dir" -maxdepth 1 -type f \( -iname '*.exe' -o -iname '*.com' -o -iname '*.dll' \) -print | sort)

printf 'package\tversion\tlicense_file_count\tstatus\n' > "$evidence_dir/license-manifest.tsv"
printf 'package\tversion\tpackage_homepage\tdeclared_license\tsource_url\tsource_sha256\tstatus\n' \
  > "$evidence_dir/source-index.tsv"
mpv_commit=$(git -C "$source_dir" rev-parse HEAD)
mpv_source_url=${MPV_SOURCE_ARCHIVE_URL:-"https://github.com/mpv-player/mpv/archive/$mpv_commit.tar.gz"}
mpv_source_sha=${MPV_SOURCE_ARCHIVE_SHA256:-MISSING}
if [ "$mpv_source_sha" = MISSING ]; then mpv_source_status=PENDING_MANUAL_SOURCE_VERIFICATION; else mpv_source_status=VERIFIED; fi
printf 'mpv-player/mpv\t%s\thttps://github.com/mpv-player/mpv\tGPL-2.0-or-later\t%s\t%s\t%s\n' \
  "$mpv_commit" "$mpv_source_url" "$mpv_source_sha" "$mpv_source_status" \
  >> "$evidence_dir/source-index.tsv"
for package in "${!packages[@]}"; do
  package_version=$(pacman -Q "$package" | awk '{print $2}')
  package_info=$(LC_ALL=C pacman -Qi "$package")
  printf '%s\n' "$package_info" > "$evidence_dir/package-metadata/$package.txt"
  declared_license=$(printf '%s\n' "$package_info" | sed -n 's/^Licenses[[:space:]]*: //p' | head -n 1)
  homepage=$(printf '%s\n' "$package_info" | sed -n 's/^URL[[:space:]]*: //p' | head -n 1)
  [ -n "$declared_license" ] || declared_license=MISSING
  [ -n "$homepage" ] || homepage=MISSING
  count=0
  while IFS= read -r license_file; do
    [ -f "$license_file" ] || continue
    relative=${license_file#"$mingw_prefix/"}
    destination="$evidence_dir/licenses/$package/$relative"
    mkdir -p "$(dirname "$destination")"
    cp "$license_file" "$destination"
    count=$((count + 1))
  done < <(pacman -Qlq "$package" | grep '/share/licenses/' || true)
  if [ "$count" -gt 0 ]; then license_status=COLLECTED; else license_status=MISSING_LOCAL_LICENSE; fi
  printf '%s\t%s\t%s\t%s\n' "$package" "$package_version" "$count" "$license_status" \
    >> "$evidence_dir/license-manifest.tsv"
  source_package=${package/mingw-w64-x86_64-/mingw-w64-}
  # MSYS2's binary package is libx264, while its source package omits "lib".
  # Keep this explicit instead of silently accepting a 404 candidate URL.
  case "$package" in
    mingw-w64-x86_64-libx264) source_package=mingw-w64-x264 ;;
  esac
  source_url="https://repo.msys2.org/mingw/sources/${source_package}-${package_version}.src.tar.zst"
  printf '%s\t%s\t%s\t%s\t%s\tMISSING\tPENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION\n' \
    "$package" "$package_version" "$homepage" "$declared_license" "$source_url" \
    >> "$evidence_dir/source-index.tsv"
done

printf 'Captured Windows MSYS2 runtime evidence: %s\n' "$evidence_dir"
