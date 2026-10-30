#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi

e=$1
index="$e/source-index.tsv"
backup="$e/source-index.pre-low-complexity-patched-nine.tsv"
verification="$e/low-complexity-patched-nine-verification-v1.tsv"
for required in "$index" "$e/runtime-manifest.tsv" "$e/license-manifest.tsv" \
  "$e/remaining-source-audit-summary-v1.tsv" "$e/msys2-source-package-inspection.tsv" \
  "$e/remaining-license-candidate-coverage-v1.tsv" "$e/remaining-root-license-staging-v2.tsv"; do
  [ -f "$required" ] || { echo "Missing: $required" >&2; exit 1; }
done
for output in "$backup" "$verification"; do
  [ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 1; }
done

scratch=$(mktemp -d "$e/.patched-nine-promotion.XXXXXX")
cleanup() { rm -rf "$scratch"; }
trap cleanup EXIT

cat > "$scratch/packages.tsv" <<'ROWS'
package	version	source_kind	source_sha256	patch_name	patch_sha256	license_sha256	runtime_files	patch_classification
mingw-w64-x86_64-dav1d	1.5.3-1	STANDARD_ARCHIVE	5514b5fe5970c1c3e509e5138a9839a7de84b9d54235b6e1772c956208e1401f	0001-dll-version.patch	7fc584e69c156d7d9805b38912f07f417ccd1cce5fe4ee457761e8bea9128d04	dd92c3c2247c5651606fc23a5e2d6a1ebc5ace9a3e49cbde0e12f05ad1cb1ee5	1	WINDOWS_DLL_VERSION_ONLY
mingw-w64-x86_64-libdeflate	1.25-1	STANDARD_ARCHIVE	53b756599ad6e44975bfe3224475a395e6b1c1c22783ae1216c5553fbfb8d746	002-pkg-config.patch	7feb96b6466375824af54a829dfe0d5cbd641970d64ef9fe0f9f4ab5e18040dd	4ad69099cb4374836fd27583d9991e2838cd86b6e4666ab26b2d32582c91e73a	1	PKG_CONFIG_DLL_FLAG_ONLY
mingw-w64-x86_64-libmodplug	0.8.9.0-5	STANDARD_ARCHIVE	6b2094f45342bcc7a1e76a7d936d26de877fc911fb445f1ff1b74514fdc7b486	010-mingw.patch	bfb4f76dbe4abf618c3352baf4fc316d42f0237f7ffbaaa8b346abff0594c834	49942e7b3b175f549e751feb08b5270ca6f6c5fb7a1be9f9517db275ec32c92e	1	WIN32_API_SUFFIX_ONLY
mingw-w64-x86_64-libogg	1.3.6-1	STANDARD_ARCHIVE	af94ea3c4011694b7a68904144ec1ab73c6c649152c78cb93a7df2a6c386b351	libogg-1.3.4-versioned-dll-cmake.patch	18772896694597eb60ab3f9fb6bc7629759d51a7fa0c1645da1f8d7ba11c1bf8	d2ab5758336489da61c12cc5bb757da5339c4ae9001f9bb0562b4370249af814	1	WINDOWS_EXPORT_AND_DLL_NAME_ONLY
mingw-w64-x86_64-libthai	0.1.30-1	STANDARD_ARCHIVE	e4f8d840fca132eb47aed311fc2c36dc59604b9ecd0aa310161b9d1e2cee4d03	relocatable.patch	f258c748e37a11ce20d307a9a27cf68de9543d79b7e60ebd31c7cf4398b5f6d9	20e50fe7aae3e56378ebf0417d9de904f55a0e61e4df315333e632a4d3555d95	1	WINDOWS_RUNTIME_DATA_PATH_ONLY
mingw-w64-x86_64-libwebp	1.6.0-1	STANDARD_ARCHIVE	c8c63f98e018a7595d22e8a3e65b7caf83345fed666866a6e67d153b16f48141	0001-mingw-cmake-output.patch	30ed42b782af427f57049abada30ce6d4d62318ee13014585cb352b570c68e3d	5aec868f669e384a22372a4e8a1a6cd7d44c64cd451f960ca69cc170d1e13acf	3	CMAKE_INSTALL_PATH_ONLY
mingw-w64-x86_64-opus	1.6.1-1	STANDARD_ARCHIVE	f9f4f73a700edcd35e11d7f47bcb164c850b781fa2cccb48cd30d505262b43a2	001-aarch64-features.patch	5fb0f28264492d6512acb6eec7b5e147c922751f6df30d1317114048eca01516	01e1167d54a096d123cf6dfbbeb19587278845c6481d2d66d545669846079551	1	WINDOWS_ARM_FEATURE_DETECTION_ONLY
mingw-w64-x86_64-srt	1.5.5-1	STANDARD_ARCHIVE	94cf384e3c1cf4bd1d886055d3916238b178b5ab7d8e9bb3cdfe85d5b0e84322	0006-no-msvc-compat-headers.patch	18af8a55e898b12074e797a212eda5e6f3c935dcc37745eb97a60591e80ab64e	fab3dd6bdab226f1c08630b1dd917e11fcb4ec5e1e020e2c16f83a0a13863e85	1	REMOVE_MSVC_COMPAT_HEADER_ONLY
mingw-w64-x86_64-zvbi	0.2.44-2	PINNED_GIT	9f7c6fa99246b8f021d35b50384bf7f8681838b9609f58abe16905bb515016a1	0001-zvbi-no-undefined.patch	c29b9fb68e48dee88b6a881478a51ce6b7277f5b3c2fedbfab71cd0270c66e47	01b41f9b6e262bb62063151f15988a236296bbb5eeb9752692fc7dc2fb27ec45	1	LINKER_NO_UNDEFINED_ONLY
ROWS

check_sha() {
  local actual
  actual=$(sha256sum "$1")
  actual=${actual%% *}
  [ "$actual" = "$2" ] || { echo "SHA-256 mismatch: $1" >&2; exit 1; }
}

printf 'package\tversion\tsource_sha256\tpatch_name\tpatch_sha256\tpatch_classification\tlicense_sha256\truntime_files\truntime_hashes\tstatus\n' \
  > "$scratch/verification.tsv"

while IFS=$'\t' read -r package version source_kind source_sha patch_name patch_sha license_sha runtime_count patch_class; do
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
  awk -F '\t' -v p="$package" -v v="$version" '
    NR > 1 && $1 == p && $2 == v {if ($5 != 1) exit 1; n++}
    END {if (n != 1) exit 1}' "$e/msys2-source-package-inspection.tsv"
  awk -F '\t' -v p="$package" -v v="$version" '
    NR > 1 && $1 == p && $2 == v {if ($4 != 1 || $5 != 0) exit 1; n++}
    END {if (n != 1) exit 1}' "$e/remaining-license-candidate-coverage-v1.tsv"

  staged_path=$(awk -F '\t' -v p="$package" -v v="$version" -v h="$license_sha" '
    NR > 1 && $1 == p && $2 == v {if ($5 != h || $7 != "EXACT_TEXT_ALREADY_STAGED") exit 1; print $6; n++}
    END {if (n != 1) exit 1}' "$e/remaining-root-license-staging-v2.tsv")
  check_sha "$e/$staged_path" "$license_sha"
  recorded_license_count=$(awk -F '\t' -v p="$package" -v v="$version" '
    NR > 1 && $1 == p && $2 == v {if ($4 != "COLLECTED") exit 1; print $3; n++}
    END {if (n != 1) exit 1}' "$e/license-manifest.tsv")
  actual_license_count=$(find "$e/licenses/$package" -type f | wc -l | tr -d '[:space:]')
  [ "$recorded_license_count" = "$actual_license_count" ] || {
    echo "Staged license count mismatch: $package" >&2; exit 1;
  }

  extract_dir="$scratch/$package"
  mkdir -p "$extract_dir"
  tar xf "$archive" -C "$extract_dir"
  patch_path=$(find "$extract_dir" -mindepth 2 -maxdepth 2 -type f -name "$patch_name")
  [ "$(printf '%s\n' "$patch_path" | sed '/^$/d' | wc -l | tr -d '[:space:]')" = 1 ] || {
    echo "Missing or duplicate patch: $patch_name" >&2; exit 1;
  }
  check_sha "$patch_path" "$patch_sha"

  runtime_rows=$(awk -F '\t' -v p="$package" 'NR > 1 && $5 == p {n++} END {print n+0}' "$e/runtime-manifest.tsv")
  [ "$runtime_rows" = "$runtime_count" ] || { echo "Runtime count mismatch: $package" >&2; exit 1; }
  runtime_files=
  runtime_hashes=
  while IFS=$'\t' read -r dll dll_sha; do
    [ -n "$dll" ] || continue
    check_sha "/mingw64/bin/$dll" "$dll_sha"
    runtime_files="${runtime_files}${runtime_files:+,}$dll"
    runtime_hashes="${runtime_hashes}${runtime_hashes:+,}$dll:$dll_sha"
  done < <(awk -F '\t' -v p="$package" 'NR > 1 && $5 == p {print $1 "\t" $2}' "$e/runtime-manifest.tsv" | sort)

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tVERIFIED\n' \
    "$package" "$version" "$source_sha" "$patch_name" "$patch_sha" "$patch_class" \
    "$license_sha" "$runtime_files" "$runtime_hashes" >> "$scratch/verification.tsv"
done < "$scratch/packages.tsv"

awk -F '\t' -v OFS='\t' 'NR == FNR {if (FNR > 1) promote[$1 SUBSEP $2]=$4; next}
  FNR == 1 {print; next}
  (($1 SUBSEP $2) in promote) {$6=promote[$1 SUBSEP $2]; $7="VERIFIED"; n++}
  {print}
  END {if (n != 9) exit 1}' "$scratch/packages.tsv" "$index" > "$scratch/source-index.tsv"

cp "$index" "$backup"
mv "$scratch/source-index.tsv" "$index"
mv "$scratch/verification.tsv" "$verification"
echo "Promoted nine low-complexity patched packages after source, patch, license, and runtime verification."
