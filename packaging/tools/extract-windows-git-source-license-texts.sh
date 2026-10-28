#!/usr/bin/env bash
set -euo pipefail

# Extract required texts from the three MSYS2 source packages that retain a
# bare Git checkout rather than an upstream tarball.  The commit IDs and paths
# are deliberately explicit review evidence, not guesses from branch heads.
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
evidence_dir=$1
packages_dir="$evidence_dir/source-packages"
suffix=${GIT_SOURCE_LICENSE_EXTRACTION_SUFFIX:-}
if [ -n "$suffix" ]; then
  case "$suffix" in *[!A-Za-z0-9._-]*) echo "Invalid output suffix: $suffix" >&2; exit 2 ;; esac
  output_dir="$evidence_dir/licenses-from-verified-git-sources-$suffix"
  report="$evidence_dir/source-license-git-extraction-$suffix.tsv"
else
  output_dir="$evidence_dir/licenses-from-verified-git-sources"
  report="$evidence_dir/source-license-git-extraction.tsv"
fi
[ -d "$packages_dir" ] || { echo "Missing source-package directory" >&2; exit 2; }
if [ -e "$output_dir" ] || [ -e "$report" ]; then
  echo "Refusing to overwrite existing Git extraction evidence" >&2; exit 2
fi
for command in git mktemp sha256sum tar; do command -v "$command" >/dev/null || exit 2; done
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$output_dir"
printf 'package\tversion\tsource_archive_sha256\tgit_commit\tsource_member\textracted_path\textracted_sha256\tstatus\n' > "$report"

extract() {
  package=$1 version=$2 archive=$3 repo_rel=$4 commit=$5 member=$6
  archive_path="$packages_dir/$archive"
  [ -f "$archive_path" ] || { echo "Missing source archive: $archive_path" >&2; exit 1; }
  archive_sha=$(sha256sum "$archive_path" | awk '{print $1}')
  package_work="$work/$package"
  mkdir -p "$package_work"
  tar -xf "$archive_path" -C "$package_work"
  repo="$package_work/$repo_rel"
  git --git-dir="$repo" cat-file -e "$commit:$member"
  mkdir -p "$output_dir/$package"
  destination="$output_dir/$package/${member//\//_}"
  git --git-dir="$repo" show "$commit:$member" > "$destination"
  text_sha=$(sha256sum "$destination" | awk '{print $1}')
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\tEXTRACTED_NEEDS_REVIEW\n' \
    "$package" "$version" "$archive_sha" "$commit" "$member" "${destination#"$evidence_dir/"}" "$text_sha" >> "$report"
}

extract mingw-w64-x86_64-libx264 0.165.r3222.b35605a-2 mingw-w64-x86_64-libx264-0.165.r3222.b35605a-2.src.tar.zst mingw-w64-x264/x264 b35605ace3ddf7c1a5d67a2eb553f034aef41d55 COPYING
extract mingw-w64-x86_64-rtmpdump 2.6-1 mingw-w64-x86_64-rtmpdump-2.6-1.src.tar.zst mingw-w64-rtmpdump/rtmpdump 138fdb258d9fc26f1843fd1b891180416c9dc575 COPYING
extract mingw-w64-x86_64-rtmpdump 2.6-1 mingw-w64-x86_64-rtmpdump-2.6-1.src.tar.zst mingw-w64-rtmpdump/rtmpdump 138fdb258d9fc26f1843fd1b891180416c9dc575 librtmp/COPYING
extract mingw-w64-x86_64-luajit 2.1.1779665312-1 mingw-w64-x86_64-luajit-2.1.1779665312-1.src.tar.zst mingw-w64-luajit/luajit 8f421c81ec6aaae0bcd80e01f4353de200afbbc5 COPYRIGHT
echo "Wrote: $report"
