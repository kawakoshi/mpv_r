#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi

evidence_dir=$1
for required in runtime-manifest.tsv license-manifest.tsv source-index.tsv \
  mpv-source.txt mpv-source.patch build-environment.txt meson-buildoptions.json \
  meson-dependencies.json ldd licenses package-metadata; do
  if [ ! -e "$evidence_dir/$required" ]; then
    echo "Missing Windows release evidence: $evidence_dir/$required" >&2
    exit 1
  fi
done

if awk -F '\t' 'NR > 1 && $8 != "SOURCE_BUILD" && $8 != "MSYS2_PACKAGE_IDENTIFIED" {print; bad=1} END {exit bad}' \
  "$evidence_dir/runtime-manifest.tsv"; then :; else
  echo "Unidentified runtime files block release." >&2
  exit 1
fi
if awk -F '\t' 'NR > 1 && $4 != "COLLECTED" {print; bad=1} END {exit bad}' \
  "$evidence_dir/license-manifest.tsv"; then :; else
  echo "Missing installed license texts block release." >&2
  exit 1
fi
if awk -F '\t' 'NR > 1 && ($5 == "MISSING" || $6 == "MISSING" || $7 != "VERIFIED") {print; bad=1} END {exit bad}' \
  "$evidence_dir/source-index.tsv"; then :; else
  echo "Unverified corresponding-source records block release." >&2
  exit 1
fi

echo "Windows self-build evidence is complete: $evidence_dir"
