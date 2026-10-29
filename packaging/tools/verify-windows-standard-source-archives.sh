#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 1 ]; then echo "Usage: $0 evidence-dir" >&2; exit 2; fi
e=$1
i="$e/msys2-source-package-inspection.tsv"
o="$e/standard-source-archive-verification.tsv"
[ -f "$i" ] && [ ! -e "$o" ] || exit 2
printf 'package\tversion\tarchive_sha256\tpkgbuild_license\tnested_source\tstatus\n' > "$o"
while IFS=$'\t' read -r p v sha lic patches nested outer status; do
  [ "$p" = package ] && continue
  case "$nested" in NONE|*';'*) continue ;; esac
  printf '%s\t%s\t%s\t%s\t%s\tSTANDARD_ARCHIVE_CANDIDATE_NEEDS_UPSTREAM_SHA_REVIEW\n' "$p" "$v" "$sha" "$lic" "$nested" >> "$o"
done < "$i"
echo "Wrote: $o"
