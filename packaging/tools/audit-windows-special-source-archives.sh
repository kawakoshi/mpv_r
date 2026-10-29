#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
evidence_dir=$1
archives="$evidence_dir/source-packages"
inspection="$evidence_dir/msys2-source-package-inspection.tsv"
report="$evidence_dir/special-source-archive-audit-v1.tsv"
licenses="$evidence_dir/special-source-license-candidates-v1.tsv"
texts="$evidence_dir/special-source-license-texts-v1"
[ -f "$inspection" ] || { echo "Missing: $inspection" >&2; exit 2; }
for output in "$report" "$licenses" "$texts"; do
  [ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 2; }
done
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
mkdir -p "$texts"
printf 'package\tversion\tmsys2_archive_sha256\tupstream_member\tupstream_url\texpected_sha256\tactual_sha256\trole\tstatus\n' > "$report"
printf 'package\tversion\tupstream_member\tlicense_member\textracted_path\tsha256\tstatus\n' > "$licenses"

while IFS='|' read -r short_name version source_dir member role; do
  package="mingw-w64-x86_64-$short_name"
  outer="$archives/${package}-${version}.src.tar.zst"
  expected_outer=$(awk -F '\t' -v p="$package" -v v="$version" \
    'NR>1 && $1==p && $2==v {print $3; exit}' "$inspection")
  [ -f "$outer" ] && [ -n "$expected_outer" ] || { echo "Missing source archive: $package" >&2; exit 1; }
  actual_outer=$(sha256sum "$outer" | awk '{print $1}')
  [ "$actual_outer" = "$expected_outer" ] || { echo "Source archive mismatch: $package" >&2; exit 1; }
  srcinfo="$scratch_dir/SRCINFO"
  tar -xOf "$outer" "$source_dir/.SRCINFO" > "$srcinfo"
  filename=${member##*/}
  mapping=$(awk -v wanted="$filename" '
    /^[[:space:]]*source = / {v=$0; sub(/^[[:space:]]*source = /,"",v); source[++n]=v}
    /^[[:space:]]*sha256sums = / {v=$0; sub(/^[[:space:]]*sha256sums = /,"",v); sum[++m]=v}
    END {
      if (n!=m) exit 2
      for (j=1;j<=n;j++) {
        name=source[j]; sub(/.*\//,"",name); sub(/[?#].*/,"",name)
        if (name==wanted) {print source[j] "\t" sum[j]; matches++}
      }
      if (matches!=1) exit 3
    }' "$srcinfo") || { echo "Cannot map source in SRCINFO: $package $member" >&2; exit 1; }
  url=${mapping%%$'\t'*}
  expected_sha=${mapping#*$'\t'}
  source_file="$scratch_dir/source"
  tar -xOf "$outer" "$member" > "$source_file"
  actual_sha=$(sha256sum "$source_file" | awk '{print $1}')
  [ "$actual_sha" = "$expected_sha" ] || { echo "Upstream hash mismatch: $package $member" >&2; exit 1; }
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tUPSTREAM_SHA_MATCH\n' \
    "$package" "$version" "$actual_outer" "$member" "$url" "$expected_sha" "$actual_sha" "$role" >> "$report"
  [ "$role" = PRIMARY_SOURCE ] || continue
  listing="$scratch_dir/listing"
  case "$member" in
    *.tar.lz) bsdtar -tf "$source_file" > "$listing" ;;
    *) tar -tf "$source_file" > "$listing" ;;
  esac
  count=0
  while IFS= read -r license_member; do
    count=$((count + 1))
    output="$texts/$package/$(printf '%03d' "$count")-${license_member##*/}"
    mkdir -p "$(dirname "$output")"
    case "$member" in
      *.tar.lz) bsdtar -xOf "$source_file" "$license_member" > "$output" ;;
      *) tar -xOf "$source_file" "$license_member" > "$output" ;;
    esac
    sha=$(sha256sum "$output" | awk '{print $1}')
    printf '%s\t%s\t%s\t%s\t%s\t%s\tEXTRACTED_NEEDS_REVIEW\n' \
      "$package" "$version" "$member" "$license_member" "${output#"$evidence_dir/"}" "$sha" >> "$licenses"
  done < <(awk 'tolower($0) ~ /(^|\/)(copying|license|licence|copyright|notice)(\.[^/]*)?$/ && $0 !~ /\/$/' "$listing")
  [ "$count" -gt 0 ] || { echo "No license candidate in primary source: $package" >&2; exit 1; }
done <<'PACKAGES'
libxml2|2.15.3-1|mingw-w64-libxml2|mingw-w64-libxml2/libxml2-2.15.3.tar.xz|PRIMARY_SOURCE
libxml2|2.15.3-1|mingw-w64-libxml2|mingw-w64-libxml2/xmlts20130923.tar.gz|AUXILIARY_TEST_SOURCE
gettext-runtime|1.0-1|mingw-w64-gettext|mingw-w64-gettext/gettext-1.0.tar.lz|PRIMARY_SOURCE
graphite2|1.3.15-1|mingw-w64-graphite2|mingw-w64-graphite2/graphite2-1.3.15.tgz|PRIMARY_SOURCE
PACKAGES
echo "Wrote: $report"
echo "Wrote: $licenses"
