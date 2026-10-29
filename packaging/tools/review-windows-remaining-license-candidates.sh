#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
evidence_dir=$1
summary="$evidence_dir/remaining-source-audit-summary-v1.tsv"
standard="$evidence_dir/standard-license-candidates-v1.tsv"
git="$evidence_dir/git-source-license-candidates-v1.tsv"
special="$evidence_dir/special-source-license-candidates-v1.tsv"
review="$evidence_dir/remaining-license-candidate-review-v1.tsv"
coverage="$evidence_dir/remaining-license-candidate-coverage-v1.tsv"
for required in "$summary" "$standard" "$git" "$special"; do
  [ -f "$required" ] || { echo "Missing: $required" >&2; exit 2; }
done
for output in "$review" "$coverage"; do
  [ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 2; }
done

tmp_review=$(mktemp)
tmp_coverage=$(mktemp)
trap 'rm -f "$tmp_review" "$tmp_coverage"' EXIT
printf 'package\tversion\tsource_kind\tlicense_member\textracted_path\tsha256\tscope\treview_status\n' > "$tmp_review"

for candidate_file in "$standard" "$git" "$special"; do
  case "$candidate_file" in
    "$standard") source_kind=STANDARD_ARCHIVE ;;
    "$git") source_kind=PINNED_GIT ;;
    "$special") source_kind=SPECIAL_ARCHIVE ;;
  esac
  while IFS=$'\t' read -r package version source_detail member path expected_sha status; do
    [ "$package" = package ] && continue
    [ "$status" = EXTRACTED_NEEDS_REVIEW ] || { echo "Unexpected extraction status: $package" >&2; exit 1; }
    file="$evidence_dir/$path"
    [ -f "$file" ] || { echo "Missing extracted license candidate: $file" >&2; exit 1; }
    actual_sha=$(sha256sum "$file")
    actual_sha=${actual_sha%% *}
    [ "$actual_sha" = "$expected_sha" ] || { echo "License text hash mismatch: $file" >&2; exit 1; }
    case "$source_kind:$member" in
      PINNED_GIT:*/*) scope=NESTED_SOURCE_TEXT ;;
      PINNED_GIT:*) scope=PACKAGE_ROOT_TEXT ;;
      *:*/*/*) scope=NESTED_SOURCE_TEXT ;;
      *:*/*) scope=PACKAGE_ROOT_TEXT ;;
      *) echo "Unexpected license path: $package $member" >&2; exit 1 ;;
    esac
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\tNEEDS_CONTENT_AND_BUILD_REVIEW\n' \
      "$package" "$version" "$source_kind" "$member" "$path" "$expected_sha" "$scope" >> "$tmp_review"
  done < "$candidate_file"
done

awk -F '\t' -v OFS='\t' '
  FNR == 1 {next}
  FILENAME == ARGV[1] {
    key=$1 SUBSEP $2
    expected[key]=$3
    order[++n]=key
    package[key]=$1; version[key]=$2
    next
  }
  {
    key=$1 SUBSEP $2
    if (!(key in expected) || expected[key] != $3) {
      print "Unexpected license candidate: " $1 > "/dev/stderr"; bad=1
    }
    if ($7 == "PACKAGE_ROOT_TEXT") root[key]++
    else if ($7 == "NESTED_SOURCE_TEXT") nested[key]++
    else {print "Unknown scope: " $7 > "/dev/stderr"; bad=1}
    total++
  }
  END {
    print "package", "version", "source_kind", "package_root_texts", "nested_source_texts", "status"
    for (i=1; i<=n; i++) {
      key=order[i]
      if (root[key] < 1) {print "No root license candidate: " package[key] > "/dev/stderr"; bad=1}
      print package[key], version[key], expected[key], root[key]+0, nested[key]+0, "CONTENT_AND_BUILD_REVIEW_PENDING"
    }
    if (n != 65 || total != 220) {
      print "Unexpected counts: packages=" n " candidates=" total > "/dev/stderr"
      bad=1
    }
    if (bad) exit 1
  }' "$summary" "$tmp_review" > "$tmp_coverage"

mv "$tmp_review" "$review"
mv "$tmp_coverage" "$coverage"
echo "Wrote: $review (220 hash-checked texts)"
echo "Wrote: $coverage (65 packages)"
