#!/usr/bin/env bash
set -euo pipefail

# Audit the single-archive candidates without executing untrusted PKGBUILDs.
# All output is review evidence; matching an archive is not license clearance.
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi

evidence_dir=$1
candidates="$evidence_dir/standard-source-archive-verification.tsv"
archives="$evidence_dir/source-packages"
archive_report="$evidence_dir/standard-upstream-sha-audit-v1.tsv"
license_report="$evidence_dir/standard-license-candidates-v1.tsv"
license_dir="$evidence_dir/standard-license-texts-v1"
for required in "$candidates" "$archives"; do
  [ -e "$required" ] || { echo "Missing input: $required" >&2; exit 2; }
done
for output in "$archive_report" "$license_report" "$license_dir"; do
  [ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 2; }
done
for program in awk basename mktemp sha256sum tar; do
  command -v "$program" >/dev/null 2>&1 || { echo "Missing command: $program" >&2; exit 2; }
done

scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
mkdir -p "$license_dir"
printf 'package\tversion\tmsys2_archive_sha256\tupstream_member\tupstream_url\texpected_sha256\tactual_sha256\tstatus\n' > "$archive_report"
printf 'package\tversion\tupstream_member\tlicense_member\textracted_path\tsha256\tstatus\n' > "$license_report"

while IFS=$'\t' read -r package version outer_sha declared_license member candidate_status; do
  [ "$package" = package ] && continue
  outer="$archives/${package}-${version}.src.tar.zst"
  if [ ! -f "$outer" ]; then
    printf '%s\t%s\t%s\t%s\t-\t-\t-\tMISSING_MSYS2_ARCHIVE\n' \
      "$package" "$version" "$outer_sha" "$member" >> "$archive_report"
    continue
  fi
  measured_outer=$(sha256sum "$outer" | awk '{print $1}')
  if [ "$measured_outer" != "$outer_sha" ]; then
    printf '%s\t%s\t%s\t%s\t-\t-\t-\tMSYS2_ARCHIVE_SHA_MISMATCH\n' \
      "$package" "$version" "$outer_sha" "$member" >> "$archive_report"
    continue
  fi

  source_name=${member##*/}
  source_dir=${member%/*}
  srcinfo_member="$source_dir/.SRCINFO"
  srcinfo="$scratch_dir/SRCINFO"
  if ! tar -xOf "$outer" "$srcinfo_member" > "$srcinfo"; then
    printf '%s\t%s\t%s\t%s\t-\t-\t-\tMISSING_SRCINFO\n' \
      "$package" "$version" "$outer_sha" "$member" >> "$archive_report"
    continue
  fi
  # Match the source filename to its position in .SRCINFO's parallel source
  # and sha256sums fields. A different count is ambiguous and blocks matching.
  mapping=$(awk -v wanted="$source_name" '
    /^[[:space:]]*source = / {
      value=$0; sub(/^[[:space:]]*source = /,"",value)
      n++; source[n]=value
    }
    /^[[:space:]]*sha256sums = / {
      value=$0; sub(/^[[:space:]]*sha256sums = /,"",value)
      m++; sum[m]=value
    }
    END {
      if (n != m) exit 2
      for (j=1;j<=n;j++) {
        url=source[j]
        filename=url; sub(/.*\//,"",filename); sub(/[?#].*/,"",filename)
        if (index(filename,"::")) sub(/.*::/,"",filename)
        if (filename==wanted || index(url,wanted "::")==1) {
          print url "\t" sum[j]
          matches++
        }
      }
      if (matches!=1) exit 3
    }
  ' "$srcinfo") || mapping=''
  if [ -z "$mapping" ]; then
    printf '%s\t%s\t%s\t%s\t-\t-\t-\tUNMAPPED_SOURCE_OR_CHECKSUM\n' \
      "$package" "$version" "$outer_sha" "$member" >> "$archive_report"
    continue
  fi
  upstream_url=${mapping%%$'\t'*}
  expected_sha=${mapping#*$'\t'}
  upstream_file="$scratch_dir/upstream-archive"
  if ! tar -xOf "$outer" "$member" > "$upstream_file"; then
    printf '%s\t%s\t%s\t%s\t%s\t%s\t-\tMISSING_UPSTREAM_MEMBER\n' \
      "$package" "$version" "$outer_sha" "$member" "$upstream_url" "$expected_sha" >> "$archive_report"
    continue
  fi
  actual_sha=$(sha256sum "$upstream_file" | awk '{print $1}')
  if [ "$expected_sha" != "$actual_sha" ]; then
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\tUPSTREAM_SHA_MISMATCH\n' \
      "$package" "$version" "$outer_sha" "$member" "$upstream_url" "$expected_sha" "$actual_sha" >> "$archive_report"
    continue
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\tUPSTREAM_SHA_MATCH\n' \
    "$package" "$version" "$outer_sha" "$member" "$upstream_url" "$expected_sha" "$actual_sha" >> "$archive_report"

  if ! tar -tf "$upstream_file" > "$scratch_dir/contents"; then
    printf '%s\t%s\t%s\t-\t-\t-\tUNREADABLE_UPSTREAM_ARCHIVE\n' \
      "$package" "$version" "$member" >> "$license_report"
    continue
  fi
  found=0
  while IFS= read -r license_member; do
    # Preserve the path in the report; use a numbered basename in the output
    # directory to avoid collisions between nested components.
    found=$((found + 1))
    output="$license_dir/$package/$(printf '%03d' "$found")-$(basename "$license_member")"
    mkdir -p "$(dirname "$output")"
    if ! tar -xOf "$upstream_file" "$license_member" > "$output"; then
      printf '%s\t%s\t%s\t%s\t-\t-\tEXTRACTION_FAILED\n' \
        "$package" "$version" "$member" "$license_member" >> "$license_report"
      continue
    fi
    text_sha=$(sha256sum "$output" | awk '{print $1}')
    printf '%s\t%s\t%s\t%s\t%s\t%s\tEXTRACTED_NEEDS_REVIEW\n' \
      "$package" "$version" "$member" "$license_member" "${output#"$evidence_dir/"}" "$text_sha" >> "$license_report"
  done < <(awk 'tolower($0) ~ /(^|\/)(copying|license|licence|copyright|notice)(\.[^/]*)?$/ && $0 !~ /\/$/' "$scratch_dir/contents")
  if [ "$found" -eq 0 ]; then
    printf '%s\t%s\t%s\t-\t-\t-\tNO_LICENSE_FILENAME_CANDIDATE\n' \
      "$package" "$version" "$member" >> "$license_report"
  fi
done < "$candidates"

echo "Wrote: $archive_report"
echo "Wrote: $license_report"
