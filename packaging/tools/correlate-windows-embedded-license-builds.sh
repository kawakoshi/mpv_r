#!/usr/bin/env bash
set -euo pipefail

# Record the build-configuration correlation for embedded-license candidates.
# It intentionally produces a separate evidence layer and never changes the
# release manifest by itself.
if [ "$#" -ne 1 ]; then echo "Usage: $0 windows-evidence-dir" >&2; exit 2; fi
evidence_dir=$1
input="$evidence_dir/source-license-classification-v1.tsv"
output="$evidence_dir/source-license-build-correlation-v1.tsv"
[ -f "$input" ] || { echo "Missing: $input" >&2; exit 2; }
[ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 2; }
printf 'package\tversion\tsource_member\tdecision\tevidence\n' > "$output"
while IFS=$'\t' read -r package version member path classification rationale; do
  [ "$classification" = RETAIN_PENDING_EMBEDDED_COMPONENT_REVIEW ] || continue
  case "$package:$member" in
    mingw-w64-x86_64-libvpx:*googletest*|mingw-w64-x86_64-libvpx:*libwebm*|mingw-w64-x86_64-libvpx:*libyuv*)
      decision=EXCLUDE_CONFIRMED_NON_RUNTIME
      evidence='MSYS2 libvpx PKGBUILD disables examples and unit tests; this source-tree component is confined to those disabled areas.' ;;
    mingw-w64-x86_64-gnutls:*)
      decision=RETAIN_RUNTIME_COMPONENT_LICENSE
      evidence='MSYS2 GnuTLS x86_64 shared build does not disable hardware acceleration or these embedded components.' ;;
    mingw-w64-x86_64-openal:*)
      decision=RETAIN_RUNTIME_COMPONENT_LICENSE
      evidence='MSYS2 OpenAL shared DLL build does not disable this embedded component; tests are a separate check phase.' ;;
    mingw-w64-x86_64-libvpx:*)
      decision=RETAIN_RUNTIME_COMPONENT_LICENSE
      evidence='MSYS2 libvpx runtime codec build does not exclude this embedded source component.' ;;
    *) echo "Unexpected embedded candidate: $package $member" >&2; exit 1 ;;
  esac
  printf '%s\t%s\t%s\t%s\t%s\n' "$package" "$version" "$member" "$decision" "$evidence" >> "$output"
done < "$input"
echo "Wrote: $output"
