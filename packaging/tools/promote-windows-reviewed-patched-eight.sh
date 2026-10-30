#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi

e=$1
index="$e/source-index.tsv"
backup="$e/source-index.pre-reviewed-patched-eight.tsv"
verification="$e/reviewed-patched-eight-verification-v1.tsv"
for required in "$index" "$e/runtime-manifest.tsv" "$e/license-manifest.tsv" \
  "$e/remaining-source-audit-summary-v1.tsv" "$e/msys2-source-package-inspection.tsv" \
  "$e/remaining-license-candidate-coverage-v1.tsv" "$e/remaining-root-license-staging-v2.tsv"; do
  [ -f "$required" ] || { echo "Missing: $required" >&2; exit 1; }
done
for output in "$backup" "$verification"; do
  [ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 1; }
done

scratch=$(mktemp -d "$e/.reviewed-eight-promotion.XXXXXX")
cleanup() { rm -rf "$scratch"; }
trap cleanup EXIT

cat > "$scratch/packages.tsv" <<'ROWS'
package	version	source_kind	source_sha256	root_text_sha256	patch_count	patch_set_sha256	runtime_count	patch_classification
mingw-w64-x86_64-fontconfig	2.18.1-1	STANDARD_ARCHIVE	9251155f41ac7dfa5ad2b8f2224f732659b8b1ab9263b54f2801054f3b9fb864	51a51aa9823704fd90bccc616cdd17ebabb5b2b3e9cbde886ca02c7002288067	2	8cbd5d815ca986c8617410aaac9fdfa00d1b581def49dde099c4a62b0da3833f	1	WINDOWS_CONFIG_INSTALL_ONLY
mingw-w64-x86_64-freetype	2.14.3-1	STANDARD_ARCHIVE	ee8071d0a6e82a274e959902898115f4c9c376a2a8e209d83dfe746c18004ec0	bd36c8b474855fa294c2ec5c184544478ef3720aad37d65a6296a4f264fd2d3b	2	9f26b66cd04dbb9b3d767ff02eac1a38b5cd457d11a66caa94f4cca1c9ac63db	1	ENABLE_UPSTREAM_RENDERING_AND_VALIDATORS
mingw-w64-x86_64-libva	2.23.0-1	STANDARD_ARCHIVE	4affa02e7040ab7aa61942c8d191a834da32f7e6658576f3eccb65f1ae968043	c86a782ee845b52472dae9b9d79fb915d333628ac0efe49cdce63644814931de	2	896e540d40b15f6948b5ee64c7d47cad2f84741aa5041a2380e148cd438d9184	2	WINDOWS_DRIVER_PATH_AND_LIBRARY_TYPE
mingw-w64-x86_64-vid.stab	1.1.1-1	PINNED_GIT	4fa5b0817e86fd80d4354b08ff9591060d36a8aabf9039a963e37755375d9496	03f095c5c70ea18ffb2b89dd58e4ee57e4f613d04632993f90c890f4cc125b99	2	b19d8638bd5c1a35f0994e332099a77866c296b0dd49b5f4171b58a786cc420a	1	OPENMP_LINK_AND_ARCH_FEATURE_DETECTION
mingw-w64-x86_64-bzip2	1.0.8-3	STANDARD_ARCHIVE	b818b3d164cd409b1fd883e3ecc056c5bc4d6cad408e871f2781bc11faf5a413	c6dbbf828498be844a89eaa3b84adbab3199e342eb5cb2ed2f0d4ba7ec0f38a3	3	19024873a959fcaab54201b9a60085f0eaf3e015f67464eeeaa62bacdcfd5e95	1	WINDOWS_PORTABILITY_BUILD_AND_CLI_PROGRESS
mingw-w64-x86_64-gdk-pixbuf2	2.44.6-1	STANDARD_ARCHIVE	f2c9624b2e36f8e3ce5489856d9afd40693cbfd98d04a25550615871358de5f5	dc626520dcd53a22f727af3ee42c770e56c97a64fe3adb063799d8ab032fe551	3	dd1d0ff3f4896db075993a11dc79f794880c93c99af01900d120f702decc6b2c	1	WINDOWS_DLLMAIN_AND_BUILTIN_LOADERS
mingw-w64-x86_64-gsm	1.0.24-1	STANDARD_ARCHIVE	623729958cd0ca08e15ff6a51a54aa1bb73fe0356c29a42fc35342087497d61a	81c68a3374937ed9b5e4929c709e81a2c4b35b5d1f450ecf8c473e2daea46ff6	4	851d4c0d06bb1e245d792de3b8445b612e132df983a75a8949eb2d86fda1f1f5	1	MINGW_BUILD_INSTALL_AND_CONFIG
mingw-w64-x86_64-jbigkit	2.1-5	STANDARD_ARCHIVE	402e264e13ffd10424d3217e83076d9e1e3ab0db16303a33d42a4bd4cda4088b	91df39d1816bfb17a4dda2d3d2c83b1f6f2d38d53e53e41e8f97ad5ac46a0cad	5	0cf3420bfe3e41ab6f32ff7b4d0518cf28afc495ed45452320e3148fa4c75f54	1	SHARED_LIBRARY_BUILD_AND_TOOL_MANPAGES
ROWS

check_sha() {
  local actual
  actual=$(sha256sum "$1"); actual=${actual%% *}
  [ "$actual" = "$2" ] || { echo "SHA-256 mismatch: $1" >&2; exit 1; }
}

printf 'package\tversion\tsource_sha256\troot_text_sha256\tpatch_count\tpatch_set_sha256\tpatch_classification\truntime_files\truntime_hashes\tlicense_evidence\tstatus\n' \
  > "$scratch/verification.tsv"

while IFS=$'\t' read -r package version source_kind source_sha root_sha patch_count patch_set_sha runtime_count patch_class; do
  [ "$package" = package ] && continue
  archive="$e/source-packages/$package-$version.src.tar.zst"
  [ -f "$archive" ] || { echo "Missing source package: $archive" >&2; exit 1; }
  check_sha "$archive" "$source_sha"

  expected_upstream=UPSTREAM_SHA_MATCH
  [ "$source_kind" = PINNED_GIT ] && expected_upstream=PINNED_REF_PRESENT_NEEDS_LICENSE_REVIEW
  source_url=$(awk -F '\t' -v p="$package" -v v="$version" -v k="$source_kind" -v h="$source_sha" -v u="$expected_upstream" '
    NR > 1 && $1 == p && $2 == v {if ($3 != k || $5 != h || $7 != u || $8 != "LICENSE_REVIEW_PENDING") exit 1; print $4; n++}
    END {if (n != 1) exit 1}' "$e/remaining-source-audit-summary-v1.tsv")
  awk -F '\t' -v p="$package" -v v="$version" -v u="$source_url" '
    NR > 1 && $1 == p && $2 == v {if ($5 != u || $6 != "MISSING" || $7 != "PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION") exit 1; n++}
    END {if (n != 1) exit 1}' "$index"
  awk -F '\t' -v p="$package" -v v="$version" -v c="$patch_count" '
    NR > 1 && $1 == p && $2 == v {if ($5 != c) exit 1; n++}
    END {if (n != 1) exit 1}' "$e/msys2-source-package-inspection.tsv"
  awk -F '\t' -v p="$package" -v v="$version" '
    NR > 1 && $1 == p && $2 == v {if ($4 != 1 || $5 != 0) exit 1; n++}
    END {if (n != 1) exit 1}' "$e/remaining-license-candidate-coverage-v1.tsv"

  extract_dir="$scratch/$package"
  mkdir -p "$extract_dir"
  tar xf "$archive" -C "$extract_dir"
  outer_root=$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d | head -n1)
  : > "$extract_dir/patches.tsv"
  for patch in "$outer_root"/*.patch; do
    [ -f "$patch" ] || continue
    patch_sha=$(sha256sum "$patch"); patch_sha=${patch_sha%% *}
    printf '%s\t%s\n' "$(basename "$patch")" "$patch_sha" >> "$extract_dir/patches.tsv"
  done
  sort -o "$extract_dir/patches.tsv" "$extract_dir/patches.tsv"
  [ "$(wc -l < "$extract_dir/patches.tsv" | tr -d '[:space:]')" = "$patch_count" ]
  check_sha "$extract_dir/patches.tsv" "$patch_set_sha"

  license_evidence=ROOT_TEXT_EXACTLY_STAGED
  if [ "$package" = mingw-w64-x86_64-freetype ]; then
    awk -F '\t' -v p="$package" -v v="$version" -v h="$root_sha" '
      NR > 1 && $1 == p && $2 == v {if ($5 != h || $7 != "ROOT_TEXT_NOT_IN_STAGED_LICENSES") exit 1; n++}
      END {if (n != 1) exit 1}' "$e/remaining-root-license-staging-v2.tsv"
    tar xf "$outer_root/freetype-2.14.3.tar.xz" -C "$extract_dir"
    check_sha "$extract_dir/freetype-2.14.3/LICENSE.TXT" "$root_sha"
    check_sha "$extract_dir/freetype-2.14.3/docs/FTL.TXT" 5a5ee54c5001bbad1cdc1a57cc3dd4c42199b2da09d39c7ee41fab002d02967f
    check_sha "$extract_dir/freetype-2.14.3/docs/GPLv2.TXT" c4120c6752c910c299e3bd9cb3a46ff262c268303ca2069b61f92f10a5656c18
    check_sha "$e/licenses/$package/share/licenses/freetype/FTL.TXT" 5a5ee54c5001bbad1cdc1a57cc3dd4c42199b2da09d39c7ee41fab002d02967f
    check_sha "$e/licenses/$package/share/licenses/freetype/GPLv2.TXT" c4120c6752c910c299e3bd9cb3a46ff262c268303ca2069b61f92f10a5656c18
    grep -Fq '`docs/FTL.TXT`' "$extract_dir/freetype-2.14.3/LICENSE.TXT"
    grep -Fq '`docs/GPLv2.TXT`' "$extract_dir/freetype-2.14.3/LICENSE.TXT"
    grep -Fq 'docs/GPLv2.TXT' "$outer_root/PKGBUILD"
    grep -Fq 'docs/FTL.TXT' "$outer_root/PKGBUILD"
    license_evidence=ROOT_GUIDE_REFERENCES_TWO_EXACTLY_STAGED_TEXTS
  else
    staged_path=$(awk -F '\t' -v p="$package" -v v="$version" -v h="$root_sha" '
      NR > 1 && $1 == p && $2 == v {if ($5 != h || $7 != "EXACT_TEXT_ALREADY_STAGED") exit 1; print $6; n++}
      END {if (n != 1) exit 1}' "$e/remaining-root-license-staging-v2.tsv")
    check_sha "$e/$staged_path" "$root_sha"
  fi

  recorded_license_count=$(awk -F '\t' -v p="$package" -v v="$version" '
    NR > 1 && $1 == p && $2 == v {if ($4 != "COLLECTED") exit 1; print $3; n++}
    END {if (n != 1) exit 1}' "$e/license-manifest.tsv")
  actual_license_count=$(find "$e/licenses/$package" -type f | wc -l | tr -d '[:space:]')
  [ "$recorded_license_count" = "$actual_license_count" ]

  runtime_rows=$(awk -F '\t' -v p="$package" 'NR > 1 && $5 == p {n++} END {print n+0}' "$e/runtime-manifest.tsv")
  [ "$runtime_rows" = "$runtime_count" ]
  runtime_files=
  runtime_hashes=
  while IFS=$'\t' read -r dll dll_sha; do
    [ -n "$dll" ] || continue
    check_sha "/mingw64/bin/$dll" "$dll_sha"
    runtime_files="${runtime_files}${runtime_files:+,}$dll"
    runtime_hashes="${runtime_hashes}${runtime_hashes:+,}$dll:$dll_sha"
  done < <(awk -F '\t' -v p="$package" 'NR > 1 && $5 == p {print $1 "\t" $2}' "$e/runtime-manifest.tsv" | sort)

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tVERIFIED\n' \
    "$package" "$version" "$source_sha" "$root_sha" "$patch_count" "$patch_set_sha" \
    "$patch_class" "$runtime_files" "$runtime_hashes" "$license_evidence" >> "$scratch/verification.tsv"
done < "$scratch/packages.tsv"

awk -F '\t' -v OFS='\t' 'NR == FNR {if (FNR > 1) promote[$1 SUBSEP $2]=$4; next}
  FNR == 1 {print; next}
  (($1 SUBSEP $2) in promote) {$6=promote[$1 SUBSEP $2]; $7="VERIFIED"; n++}
  {print}
  END {if (n != 8) exit 1}' "$scratch/packages.tsv" "$index" > "$scratch/source-index.tsv"

cp "$index" "$backup"
mv "$scratch/source-index.tsv" "$index"
mv "$scratch/verification.tsv" "$verification"
echo "Promoted eight reviewed patched packages after source, patch, license, and runtime verification."
