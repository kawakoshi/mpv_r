#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
evidence_dir=$1
sha_report="$evidence_dir/standard-upstream-sha-audit-v1.tsv"
candidate_report="$evidence_dir/standard-license-candidates-v1.tsv"
review="$evidence_dir/standard-license-review-v1.tsv"
coverage="$evidence_dir/standard-license-coverage-v1.tsv"
for input in "$sha_report" "$candidate_report"; do
  [ -f "$input" ] || { echo "Missing input: $input" >&2; exit 2; }
done
for output in "$review" "$coverage"; do
  [ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 2; }
done

printf 'package\tversion\tlicense_member\textracted_path\tsha256\tclassification\n' > "$review"
while IFS=$'\t' read -r package version upstream_member license_member path expected_sha status; do
  [ "$package" = package ] && continue
  if [ "$status" != EXTRACTED_NEEDS_REVIEW ]; then
    echo "Unresolved license candidate: $package $status" >&2
    exit 1
  fi
  file="$evidence_dir/$path"
  [ -f "$file" ] || { echo "Missing extracted text: $file" >&2; exit 1; }
  actual_sha=$(sha256sum "$file" | awk '{print $1}')
  [ "$actual_sha" = "$expected_sha" ] || { echo "Text hash mismatch: $file" >&2; exit 1; }
  relative=${license_member#*/}
  if [ "$relative" = "$license_member" ]; then
    echo "Unexpected license member path: $license_member" >&2
    exit 1
  fi
  if [[ "$relative" == */* ]]; then
    classification=NESTED_COMPONENT_OR_NON_RUNTIME_NEEDS_REVIEW
  else
    classification=PRIMARY_PACKAGE_TEXT_CANDIDATE
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$package" "$version" "$license_member" "$path" "$actual_sha" "$classification" >> "$review"
done < "$candidate_report"

awk -F '\t' 'BEGIN {OFS="\t"; print "package","version","primary_count","nested_count","status"}
  NR==FNR {if (NR>1) {expected[$1 FS $2]=1; order[++n]=$1 FS $2} next}
  NR>1 {key=$1 FS $2; if ($6=="PRIMARY_PACKAGE_TEXT_CANDIDATE") primary[key]++; else nested[key]++}
  END {for (i=1;i<=n;i++) {key=order[i]; split(key,p,FS); print p[1],p[2],primary[key]+0,nested[key]+0,(primary[key]>0?"PRIMARY_TEXT_PRESENT_NEEDS_LICENSE_REVIEW":"PRIMARY_TEXT_MISSING")}}
' "$sha_report" "$review" > "$coverage"
echo "Wrote: $review"
echo "Wrote: $coverage"
