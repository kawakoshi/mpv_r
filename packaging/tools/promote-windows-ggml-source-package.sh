#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 windows-evidence-dir" >&2
  exit 2
fi
e=$1
p=mingw-w64-x86_64-ggml
v=0.15.2.r0.g707321c4-1
commit=707321c4cf6d21cb4bc831aa8b687dbf01a521ce
url=https://repo.msys2.org/mingw/sources/mingw-w64-ggml-0.15.2.r0.g707321c4-1.src.tar.zst
source_sha=66942bff59aed6708c70bfc46e133871e5709fb3589c32c3e12251813948c31a
license_sha=94f29bbed6a22c35b992c5c6ebf0e7c92f13b836b90f36f461c9cf2f0f1d010d
index="$e/source-index.tsv"
archive="$e/source-packages/$p-$v.src.tar.zst"
backup="$e/source-index.pre-ggml-promotion.tsv"
verification="$e/ggml-source-verification-v1.tsv"
backend_gap="$e/ggml-runtime-backend-gap-v1.tsv"
for f in "$index" "$archive" "$e/remaining-source-audit-summary-v1.tsv" "$e/msys2-source-package-inspection.tsv" \
  "$e/remaining-license-candidate-coverage-v1.tsv" "$e/remaining-root-license-staging-v2.tsv" \
  "$e/license-manifest.tsv" "$e/runtime-manifest.tsv"; do
  [ -f "$f" ] || { echo "Missing: $f" >&2; exit 1; }
done
for f in "$backup" "$verification" "$backend_gap"; do [ ! -e "$f" ] || { echo "Refusing to overwrite: $f" >&2; exit 1; }; done
check_sha() { local a; a=$(sha256sum "$1"); [ "${a%% *}" = "$2" ] || exit 1; }
check_sha "$archive" "$source_sha"
awk -F '\t' -v p="$p" -v v="$v" -v u="$url" 'NR>1&&$1==p&&$2==v{if($5!=u||$6!="MISSING"||$7!="PENDING_SOURCE_PACKAGE_DOWNLOAD_AND_VERIFICATION")exit 1;n++}END{if(n!=1)exit 1}' "$index"
awk -F '\t' -v p="$p" -v v="$v" -v u="$url" -v h="$source_sha" -v c="$commit" 'NR>1&&$1==p&&$2==v{if($3!="PINNED_GIT"||$4!=u||$5!=h||$6!=c||$7!="PINNED_REF_PRESENT_NEEDS_LICENSE_REVIEW")exit 1;n++}END{if(n!=1)exit 1}' "$e/remaining-source-audit-summary-v1.tsv"
awk -F '\t' -v p="$p" -v v="$v" -v h="$source_sha" 'NR>1&&$1==p&&$2==v{if($3!=h||$5!=0)exit 1;n++}END{if(n!=1)exit 1}' "$e/msys2-source-package-inspection.tsv"
awk -F '\t' -v p="$p" -v v="$v" 'NR>1&&$1==p&&$2==v{if($4!=1||$5!=0)exit 1;n++}END{if(n!=1)exit 1}' "$e/remaining-license-candidate-coverage-v1.tsv"
awk -F '\t' -v p="$p" -v v="$v" -v h="$license_sha" 'NR>1&&$1==p&&$2==v{if($5!=h||$7!="EXACT_TEXT_ALREADY_STAGED")exit 1;n++}END{if(n!=1)exit 1}' "$e/remaining-root-license-staging-v2.tsv"
awk -F '\t' -v p="$p" -v v="$v" 'NR>1&&$1==p&&$2==v{if($3!=1||$4!="COLLECTED")exit 1;n++}END{if(n!=1)exit 1}' "$e/license-manifest.tsv"
test "$(find "$e/licenses/$p" -type f | wc -l | tr -d '[:space:]')" = 1
check_sha "$e/licenses/$p/share/licenses/ggml/LICENSE" "$license_sha"

tmp=$(mktemp -d "$e/.ggml-promotion.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
tar xf "$archive" -C "$tmp" mingw-w64-ggml/ggml mingw-w64-ggml/PKGBUILD
gitdir="$tmp/mingw-w64-ggml/ggml"
git --git-dir="$gitdir" cat-file -e "$commit^{commit}"
test "$(git --git-dir="$gitdir" rev-parse "$commit^{commit}")" = "$commit"
git --git-dir="$gitdir" show "$commit:LICENSE" > "$tmp/LICENSE"
check_sha "$tmp/LICENSE" "$license_sha"
grep -Fq '_commit="707321c4cf6d21cb4bc831aa8b687dbf01a521ce"' "$tmp/mingw-w64-ggml/PKGBUILD"
grep -Fq -- '-DGGML_BACKEND_DL=ON' "$tmp/mingw-w64-ggml/PKGBUILD"
grep -Fq -- '-DGGML_CPU_ALL_VARIANTS=ON' "$tmp/mingw-w64-ggml/PKGBUILD"
grep -Fq -- '-DGGML_BUILD_TESTS=OFF' "$tmp/mingw-w64-ggml/PKGBUILD"
git --git-dir="$gitdir" show "$commit:src/ggml-backend-reg.cpp" > "$tmp/ggml-backend-reg.cpp"
grep -Fq 'ggml_backend_load_best("cpu"' "$tmp/ggml-backend-reg.cpp"
grep -Fq 'search_paths.push_back(get_executable_path())' "$tmp/ggml-backend-reg.cpp"

printf 'file\tsha256\tstatus\n' > "$tmp/runtime.tsv"
for dll in ggml.dll ggml-base.dll; do
  expected=$(awk -F '\t' -v p="$p" -v d="$dll" 'NR>1&&$1==d&&$5==p{print $2;n++}END{if(n!=1)exit 1}' "$e/runtime-manifest.tsv")
  check_sha "/mingw64/bin/$dll" "$expected"
  printf '%s\t%s\tSHIPPED_HASH_MATCH\n' "$dll" "$expected" >> "$tmp/runtime.tsv"
done
if awk -F '\t' '$1 ~ /^ggml-cpu-.*\.dll$/ {found=1} END{exit !found}' "$e/runtime-manifest.tsv"; then
  echo "This audit script expects the known pre-fix runtime without CPU backends" >&2; exit 1
fi
backend_count=0
printf 'file\tinstalled_sha256\tcandidate_status\n' > "$tmp/backend-gap.tsv"
for dll in /mingw64/bin/ggml-cpu-*.dll; do
  [ -f "$dll" ] || continue
  backend_count=$((backend_count + 1))
  h=$(sha256sum "$dll"); h=${h%% *}
  printf '%s\t%s\tMISSING_REBUILD_REQUIRED\n' "$(basename "$dll")" "$h" >> "$tmp/backend-gap.tsv"
done
[ "$backend_count" -gt 0 ]
grep -Fq $'ggml-cpu-x64.dll\t' "$tmp/backend-gap.tsv"

awk -F '\t' -v OFS='\t' -v p="$p" -v v="$v" -v u="$url" -v h="$source_sha" 'NR==1{print;next}$1==p&&$2==v{$5=u;$6=h;$7="VERIFIED";n++}{print}END{if(n!=1)exit 1}' "$index" > "$tmp/index.tsv"
printf 'package\tversion\tcommit\tsource_sha256\tlicense_sha256\tshipped_dlls\truntime_backend_status\tstatus\n%s\t%s\t%s\t%s\t%s\t2\tCPU_BACKENDS_MISSING_REBUILD_REQUIRED\tVERIFIED\n' "$p" "$v" "$commit" "$source_sha" "$license_sha" > "$tmp/verification.tsv"
cp "$index" "$backup"
mv "$tmp/index.tsv" "$index"
mv "$tmp/verification.tsv" "$verification"
mv "$tmp/backend-gap.tsv" "$backend_gap"
echo "Promoted ggml source row and recorded the CPU-backend runtime gap."
