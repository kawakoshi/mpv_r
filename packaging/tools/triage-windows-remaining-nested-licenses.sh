#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
evidence_dir=$1
review="$evidence_dir/remaining-license-candidate-review-v1.tsv"
source_summary="$evidence_dir/remaining-source-audit-summary-v1.tsv"
runtime="$evidence_dir/runtime-manifest.tsv"
suffix=${NESTED_LICENSE_TRIAGE_SUFFIX:-v1}
case "$suffix" in *[!A-Za-z0-9._-]*) echo "Invalid output suffix: $suffix" >&2; exit 2 ;; esac
output="$evidence_dir/remaining-nested-license-build-triage-$suffix.tsv"
for required in "$review" "$source_summary" "$runtime"; do
  [ -f "$required" ] || { echo "Missing: $required" >&2; exit 2; }
done
[ ! -e "$output" ] || { echo "Refusing to overwrite: $output" >&2; exit 2; }

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
check_recipe() {
  local name=$1 package version expected_sha archive actual_sha member
  package="mingw-w64-x86_64-$name"
  version=$(awk -F '\t' -v p="$package" 'NR>1 && $1==p {print $2; exit}' "$source_summary")
  expected_sha=$(awk -F '\t' -v p="$package" 'NR>1 && $1==p {print $5; exit}' "$source_summary")
  [ -n "$version" ] && [ -n "$expected_sha" ] || { echo "Missing source summary: $package" >&2; exit 1; }
  archive="$evidence_dir/source-packages/${package}-${version}.src.tar.zst"
  [ -f "$archive" ] || { echo "Missing source archive: $archive" >&2; exit 1; }
  actual_sha=$(sha256sum "$archive")
  actual_sha=${actual_sha%% *}
  [ "$actual_sha" = "$expected_sha" ] || { echo "Source archive mismatch: $package" >&2; exit 1; }
  member=$(tar tf "$archive" | grep '/PKGBUILD$' | head -n 1)
  [ -n "$member" ] || { echo "Missing PKGBUILD: $package" >&2; exit 1; }
  tar -xOf "$archive" "$member" > "$scratch/$name.PKGBUILD"
  awk -F '\t' -v p="$package" 'NR>1 && $5==p {print $1}' "$runtime" > "$scratch/$name.runtime"
  [ -s "$scratch/$name.runtime" ] || { echo "No shipped runtime: $package" >&2; exit 1; }
}
for name in libvpl gettext-runtime gcc-libs libwinpthread aom whisper.cpp libpng libtiff libxml2 pcre2 harfbuzz cairo; do
  check_recipe "$name"
done
for marker in 'share/vpl/examples' 'package()'; do grep -Fq "$marker" "$scratch/libvpl.PKGBUILD"; done
for marker in 'package_gettext-runtime()' 'package_gettext-tools()' 'package_gettext-libtextstyle()'; do
  grep -Fq "$marker" "$scratch/gettext-runtime.PKGBUILD"
done
for marker in 'package_gcc-libs()' 'libgcc' 'libstdc++-v3/src'; do grep -Fq "$marker" "$scratch/gcc-libs.PKGBUILD"; done
for marker in 'mingw-w64-libraries/winpthreads/configure' '_install_licenses libwinpthread'; do
  grep -Fq "$marker" "$scratch/libwinpthread.PKGBUILD"
done
grep -Fq -- '-DENABLE_TESTS=OFF' "$scratch/aom.PKGBUILD"
grep -Fq -- '-DWHISPER_BUILD_TESTS=OFF' "$scratch/whisper.cpp.PKGBUILD"
grep -Fq -- '-DWHISPER_BUILD_EXAMPLES=ON' "$scratch/whisper.cpp.PKGBUILD"
grep -Fq 'Build contributed programs' "$scratch/libpng.PKGBUILD"
grep -Fq 'make check' "$scratch/libxml2.PKGBUILD"
grep -Fq 'doc/' "$scratch/libtiff.PKGBUILD" || grep -Fq 'LICENSE.md' "$scratch/libtiff.PKGBUILD"
grep -Fq -- '--enable-jit' "$scratch/pcre2.PKGBUILD"
grep -Fq -- '-Dtests=disabled' "$scratch/harfbuzz.PKGBUILD"
grep -Fq -- '-Dtests=disabled' "$scratch/cairo.PKGBUILD"
grep -Fxq 'libvpl-2.dll' "$scratch/libvpl.runtime"
grep -Fxq 'libintl-8.dll' "$scratch/gettext-runtime.runtime"
grep -Fxq 'libwinpthread-1.dll' "$scratch/libwinpthread.runtime"
for dll in libgcc_s_seh-1.dll libgomp-1.dll libstdc++-6.dll; do grep -Fxq "$dll" "$scratch/gcc-libs.runtime"; done
for pair in 'aom:libaom.dll' 'whisper.cpp:libwhisper-1.dll' 'libpng:libpng16-16.dll' 'libtiff:libtiff-6.dll' 'libxml2:libxml2-16.dll'; do
  name=${pair%%:*}
  dll=${pair#*:}
  grep -Fxq "$dll" "$scratch/$name.runtime"
done
for pair in 'pcre2:libpcre2-8-0.dll' 'harfbuzz:libharfbuzz-0.dll' 'cairo:libcairo-2.dll'; do
  name=${pair%%:*}
  dll=${pair#*:}
  grep -Fxq "$dll" "$scratch/$name.runtime"
done

printf 'package\tversion\tlicense_member\tsha256\ttriage\tevidence\n' > "$output"
count=0
while IFS=$'\t' read -r package version kind member path sha scope status; do
  [ "$package" = package ] && continue
  [ "$scope" = NESTED_SOURCE_TEXT ] || continue
  case "$package:$member" in
    mingw-w64-x86_64-libvpl:*/examples/*|mingw-w64-x86_64-libvpl:*/libvpl/test/*)
      decision=SOURCE_ONLY_SAMPLE_OR_TEST
      evidence='PKGBUILD removes share/vpl/examples; runtime-manifest ships libvpl-2.dll; source path is examples or test.' ;;
    mingw-w64-x86_64-gettext-runtime:*/gettext-tools/*|mingw-w64-x86_64-gettext-runtime:*/libtextstyle/*|mingw-w64-x86_64-gettext-runtime:*/gnulib-local/*)
      decision=DIFFERENT_SPLIT_PACKAGE
      evidence='PKGBUILD has separate package_gettext-tools and package_gettext-libtextstyle functions; runtime-manifest ships libintl-8.dll from gettext-runtime.' ;;
    mingw-w64-x86_64-gettext-runtime:*/gettext-runtime/*)
      decision=RUNTIME_COMPONENT_TEXT
      evidence='PKGBUILD package_gettext-runtime installs the gettext-runtime subtree and its license texts.' ;;
    mingw-w64-x86_64-libwinpthread:mingw-w64-libraries/winpthreads/COPYING)
      decision=RUNTIME_COMPONENT_TEXT
      evidence='PKGBUILD builds mingw-w64-libraries/winpthreads and installs this COPYING for libwinpthread.' ;;
    mingw-w64-x86_64-libwinpthread:mingw-w64-tools/*|mingw-w64-x86_64-libwinpthread:mingw-w64-libraries/libmangle/*|mingw-w64-x86_64-libwinpthread:mingw-w64-libraries/pseh/*|mingw-w64-x86_64-libwinpthread:mingw-w64-libraries/winstorecompat/*)
      decision=OTHER_SOURCE_COMPONENT
      evidence='PKGBUILD builds only mingw-w64-libraries/winpthreads for libwinpthread-1.dll.' ;;
    mingw-w64-x86_64-gcc-libs:*/gcc/ada/*|mingw-w64-x86_64-gcc-libs:*/gcc/go/*|mingw-w64-x86_64-gcc-libs:*/gcc/m2/*|mingw-w64-x86_64-gcc-libs:*/gcc/testsuite/*|mingw-w64-x86_64-gcc-libs:*/libgo/*|mingw-w64-x86_64-gcc-libs:*/libgcobol/*|mingw-w64-x86_64-gcc-libs:*/libgrust/*|mingw-w64-x86_64-gcc-libs:*/libphobos/*|mingw-w64-x86_64-gcc-libs:*/libsanitizer/*|mingw-w64-x86_64-gcc-libs:*/libffi/*|mingw-w64-x86_64-gcc-libs:*/libcody/*)
      decision=OTHER_SOURCE_COMPONENT
      evidence='PKGBUILD package_gcc-libs installs libgcc, libatomic, libgomp, libquadmath and libstdc++; shipped DLLs are libgcc_s_seh, libgomp and libstdc++.' ;;
    mingw-w64-x86_64-aom:*/third_party/googletest/*)
      decision=SOURCE_ONLY_SAMPLE_OR_TEST
      evidence='PKGBUILD configures AOM with -DENABLE_TESTS=OFF; runtime-manifest ships only libaom.dll.' ;;
    mingw-w64-x86_64-whisper.cpp:tests/*|mingw-w64-x86_64-whisper.cpp:examples/*|mingw-w64-x86_64-whisper.cpp:bindings/go/*)
      decision=SOURCE_ONLY_SAMPLE_OR_TEST
      evidence='PKGBUILD disables tests and builds examples as separate binaries; runtime-manifest ships only libwhisper-1.dll.' ;;
    mingw-w64-x86_64-libpng:*/contrib/*)
      decision=OTHER_SOURCE_COMPONENT
      evidence='PKGBUILD builds contrib/pngminus programs separately; runtime-manifest ships only libpng16-16.dll.' ;;
    mingw-w64-x86_64-libtiff:*/doc/*)
      decision=SOURCE_ONLY_SAMPLE_OR_TEST
      evidence='PKGBUILD installs libtiff; source path is documentation; runtime-manifest ships only libtiff-6.dll.' ;;
    mingw-w64-x86_64-libxml2:*/test/*|mingw-w64-x86_64-libxml2:*/result/*)
      decision=SOURCE_ONLY_SAMPLE_OR_TEST
      evidence='PKGBUILD runs make check separately; source path is test input or result; runtime-manifest ships only libxml2-16.dll.' ;;
    mingw-w64-x86_64-pcre2:*/deps/sljit/LICENSE)
      decision=RUNTIME_COMPONENT_TEXT
      evidence='PKGBUILD enables PCRE2 JIT; its deps/sljit code is the JIT compiler used by libpcre2-8-0.dll.' ;;
    mingw-w64-x86_64-harfbuzz:*/test/*|mingw-w64-x86_64-cairo:*/test/*)
      decision=SOURCE_ONLY_SAMPLE_OR_TEST
      evidence='PKGBUILD disables tests for the shared library build; source path is test-only.' ;;
    *)
      decision=BUILD_COMPONENT_REVIEW_PENDING
      evidence='Source path alone does not establish whether this text applies to a shipped DLL.' ;;
  esac
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$package" "$version" "$member" "$sha" "$decision" "$evidence" >> "$output"
  count=$((count + 1))
done < "$review"
[ "$count" -eq 140 ] || { echo "Unexpected nested candidate count: $count" >&2; exit 1; }
echo "Wrote: $output (140 nested texts; source-area triage only)"
