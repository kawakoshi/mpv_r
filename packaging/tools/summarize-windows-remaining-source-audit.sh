#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi

evidence_dir=$1
index="$evidence_dir/source-index.tsv"
reconciled="$evidence_dir/msys2-source-package-downloads-reconciled-v3.tsv"
standard="$evidence_dir/standard-upstream-sha-audit-v1.tsv"
git="$evidence_dir/git-source-commit-audit-v1.tsv"
special="$evidence_dir/special-source-archive-audit-v1.tsv"
output="$evidence_dir/remaining-source-audit-summary-v1.tsv"

for required in "$index" "$reconciled" "$standard" "$git" "$special"; do
  [ -f "$required" ] || { echo "Missing: $required" >&2; exit 2; }
done
[ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 2; }

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
awk -F '\t' -v OFS='\t' \
  -v source_index="$index" -v reconciled="$reconciled" -v standard="$standard" \
  -v git="$git" -v special="$special" '
  FNR == 1 {next}
  FILENAME == reconciled {
    key=$1 SUBSEP $2
    if (key in archive_sha) {print "Duplicate reconciled package: " $1 > "/dev/stderr"; bad=1}
    archive_url[key]=$3; archive_sha[key]=$4; archive_status[key]=$5
    archive_count++
    next
  }
  FILENAME == standard {
    key=$1 SUBSEP $2
    if (key in source_kind) {print "Duplicate standard package: " $1 > "/dev/stderr"; bad=1}
    source_kind[key]="STANDARD_ARCHIVE"
    source_sha[key]=$3; source_detail[key]=$4; source_status[key]=$8
    standard_count++
    next
  }
  FILENAME == git {
    key=$1 SUBSEP $2
    if (key in source_kind) {print "Duplicate Git package: " $1 > "/dev/stderr"; bad=1}
    source_kind[key]="PINNED_GIT"
    source_sha[key]=$3; source_detail[key]=$6; source_status[key]=$7
    git_count++
    next
  }
  FILENAME == special {
    key=$1 SUBSEP $2
    if ($8 == "PRIMARY_SOURCE") {
      if (key in source_kind) {print "Duplicate primary special package: " $1 > "/dev/stderr"; bad=1}
      source_kind[key]="SPECIAL_ARCHIVE"
      source_sha[key]=$3; source_detail[key]=$4; source_status[key]=$9
      special_count++
    } else if ($8 == "AUXILIARY_TEST_SOURCE") {
      if ($9 != "UPSTREAM_SHA_MATCH") {print "Auxiliary source mismatch: " $1 > "/dev/stderr"; bad=1}
      auxiliary_count++
    } else {print "Unknown source role: " $8 > "/dev/stderr"; bad=1}
    next
  }
  FILENAME == source_index {
    key=$1 SUBSEP $2
    if ($1 !~ /^mingw-w64-/) next
    if (!(key in archive_sha) || archive_status[key] != "RECONCILED_FROM_ARCHIVE" || archive_url[key] != $5) {
      print "Missing or mismatched MSYS2 archive: " $1 > "/dev/stderr"; bad=1
    }
    if ($7 == "VERIFIED") {
      if ($6 != archive_sha[key]) {print "Previously verified source hash mismatch: " $1 > "/dev/stderr"; bad=1}
      verified_count++
    } else if ($7 == "PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION") {
      if (!(key in source_kind) || source_sha[key] != archive_sha[key] || 
          (source_kind[key] == "PINNED_GIT" && source_status[key] != "PINNED_REF_PRESENT_NEEDS_LICENSE_REVIEW") ||
          (source_kind[key] != "PINNED_GIT" && source_status[key] != "UPSTREAM_SHA_MATCH")) {
        print "Missing or mismatched upstream audit: " $1 > "/dev/stderr"; bad=1
      }
      print $1, $2, source_kind[key], archive_url[key], archive_sha[key], source_detail[key], source_status[key], "LICENSE_REVIEW_PENDING"
      pending_count++
    } else {print "Unexpected source index status: " $1 " " $7 > "/dev/stderr"; bad=1}
    next
  }
  END {
    if (archive_count != 86 || verified_count != 21 || pending_count != 65 ||
        standard_count != 56 || git_count != 6 || special_count != 3 || auxiliary_count != 1) {
      print "Unexpected counts: archive=" archive_count " verified=" verified_count " pending=" pending_count \
        " standard=" standard_count " git=" git_count " special=" special_count " auxiliary=" auxiliary_count > "/dev/stderr"
      bad=1
    }
    if (bad) exit 1
  }' "$reconciled" "$standard" "$git" "$special" "$index" > "$tmp"

printf 'package\tversion\tsource_kind\tmsys2_source_url\tmsys2_source_sha256\tupstream_detail\tupstream_status\treview_status\n' > "$output"
cat "$tmp" >> "$output"
echo "Wrote: $output (65 pending packages; 21 already verified)"
