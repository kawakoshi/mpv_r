#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
evidence_dir=$1
archives="$evidence_dir/source-packages"
inspection="$evidence_dir/msys2-source-package-inspection.tsv"
report="$evidence_dir/git-source-commit-audit-v1.tsv"
licenses="$evidence_dir/git-source-license-candidates-v1.tsv"
texts="$evidence_dir/git-source-license-texts-v1"
[ -f "$inspection" ] || { echo "Missing: $inspection" >&2; exit 2; }
for output in "$report" "$licenses" "$texts"; do
  [ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 2; }
done
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
mkdir -p "$texts"
printf 'package\tversion\tmsys2_archive_sha256\tsrcinfo_url\trequested_ref\tresolved_commit\tstatus\n' > "$report"
printf 'package\tversion\tgit_commit\tlicense_member\textracted_path\tsha256\tstatus\n' > "$licenses"

# The final column is the bare repository path within the MSYS2 source archive.
while IFS=$'\t' read -r short_name version source_dir bare_dir; do
  package="mingw-w64-x86_64-$short_name"
  outer="$archives/${package}-${version}.src.tar.zst"
  [ -f "$outer" ] || { echo "Missing: $outer" >&2; exit 1; }
  expected_outer=$(awk -F '\t' -v p="$package" -v v="$version" \
    'NR>1 && $1==p && $2==v {print $3; exit}' "$inspection")
  actual_outer=$(sha256sum "$outer" | awk '{print $1}')
  [ -n "$expected_outer" ] && [ "$actual_outer" = "$expected_outer" ] || {
    echo "MSYS2 archive hash mismatch: $outer" >&2; exit 1;
  }
  package_dir="$scratch_dir/$short_name"
  mkdir -p "$package_dir"
  tar -xf "$outer" -C "$package_dir"
  srcinfo="$package_dir/$source_dir/.SRCINFO"
  repo="$package_dir/$source_dir/$bare_dir"
  [ -f "$srcinfo" ] && [ -d "$repo/objects" ] || {
    echo "Expected source metadata or bare Git repository missing: $package" >&2; exit 1;
  }
  source_url=$(awk '/^[[:space:]]*source = / {sub(/^[[:space:]]*source = /, ""); if ($0 ~ /git\+/) {print; exit}}' "$srcinfo")
  case "$source_url" in
    *'#commit='*) requested=${source_url##*#commit=} ;;
    *'#tag='*) requested="refs/tags/${source_url##*#tag=}" ;;
    *) echo "No pinned Git commit or tag: $package" >&2; exit 1 ;;
  esac
  resolved=$(git --git-dir="$repo" rev-parse --verify "$requested^{commit}") || {
    echo "Pinned Git ref missing: $package $requested" >&2; exit 1;
  }
  printf '%s\t%s\t%s\t%s\t%s\t%s\tPINNED_REF_PRESENT_NEEDS_LICENSE_REVIEW\n' \
    "$package" "$version" "$actual_outer" "$source_url" "$requested" "$resolved" >> "$report"
  git --git-dir="$repo" ls-tree -r --name-only "$resolved" > "$package_dir/tree-files"
  found=0
  while IFS= read -r member; do
    found=$((found + 1))
    destination="$texts/$package/$(printf '%03d' "$found")-${member##*/}"
    mkdir -p "$(dirname "$destination")"
    git --git-dir="$repo" show "$resolved:$member" > "$destination"
    sha=$(sha256sum "$destination" | awk '{print $1}')
    printf '%s\t%s\t%s\t%s\t%s\t%s\tEXTRACTED_NEEDS_REVIEW\n' \
      "$package" "$version" "$resolved" "$member" "${destination#"$evidence_dir/"}" "$sha" >> "$licenses"
  done < <(awk 'tolower($0) ~ /(^|\/)(copying|license|licence|copyright|notice)(\.[^/]*)?$/ && $0 !~ /\/$/' "$package_dir/tree-files")
  if [ "$found" -eq 0 ]; then
    printf '%s\t%s\t%s\t-\t-\t-\tNO_LICENSE_FILENAME_CANDIDATE\n' \
      "$package" "$version" "$resolved" >> "$licenses"
  fi
done <<'PACKAGES'
vid.stab	1.1.1-1	mingw-w64-vid.stab	vid.stab-1.1.1
libsoxr	0.1.3-5	mingw-w64-libsoxr	code
whisper.cpp	1~1.9.1.r41.g5ed76e9a0-1	mingw-w64-whisper.cpp	whisper.cpp
ggml	0.15.2.r0.g707321c4-1	mingw-w64-ggml	ggml
zvbi	0.2.44-2	mingw-w64-zvbi	zvbi
libwinpthread	14.0.0.r147.g31bd54ab7-1	mingw-w64-winpthreads	mingw-w64
PACKAGES

echo "Wrote: $report"
echo "Wrote: $licenses"
