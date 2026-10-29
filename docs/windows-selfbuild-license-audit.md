# Windows Self-Build Release License Audit

This checklist applies to the Windows v0.3.0 project-built runtime. It is a
release gate, not a claim that the candidate ZIP is ready to publish.

## Current Status

**Do not publish the project-built Windows ZIP yet.** The test runtime contains
mpv and more than one hundred DLLs collected from the MSYS2 MINGW64 runtime.
The current candidate package contains mpv's GPL/LGPL texts, but does not yet
contain a complete per-package notice and license set for those DLLs or the
corresponding source bundle/index.

The already published Windows v0.2.0 ZIP is a separate, third-party-build
release and is not covered by this checklist.

As of 2026-10-30, the local audit evidence contains all 86 MSYS2 source
packages used by the runtime. Their archive SHA-256 values have been
recalculated. The source index has 31 verified MSYS2 rows and 55 rows still
pending license review. For the original batch of 65, the matching MSYS2 source archives and
their upstream inputs were checked: 56 ordinary nested archives, six pinned Git
revisions, and three archives using other formats. One extra libxml2 test
archive was also hash-checked. The 65 packages yielded 220 hash-checked license
text candidates: 80 at source-package roots and 140 in nested source areas.
These counts establish provenance and text availability, not which nested
components were compiled into the shipped DLLs or which notices must ship.
The release gate remains closed.

The reproducible reports in the local Windows evidence directory are
`msys2-source-package-downloads-reconciled-v3.tsv`,
`remaining-source-audit-summary-v1.tsv`,
`remaining-license-candidate-review-v1.tsv`, and
`remaining-license-candidate-coverage-v1.tsv`. The scripts that create the last
two reports are under `packaging/tools/`. Continue with the exact PKGBUILD,
build-feature, patch, and license-content review before promoting the remaining 55 source
index rows or assembling the release license collection. In particular,
`gcc-libs`, `gettext-runtime`, `libwinpthread`, `librsvg`, and `aom`
have multiple nested texts requiring component-level review.

An exact-text comparison found that 73 of the 80 source-root texts are now in
the staged license collection. Lerc's source `NOTICE`, which includes a patent
notice, was added with its original SHA-256 and a backed-up manifest update.
The seven remaining nonmatches are `zstd`, `freetype`, `libgme`, `glib2`,
`gcc-libs`, `libwinpthread`, and `gettext-runtime`. Several are generic or empty
source-root texts while the staged package has more specific runtime license
texts. Do not copy them automatically or treat a byte difference as proof of
noncompliance; resolve each against the actual DLL and package build. The
comparison is recorded in `remaining-root-license-staging-v2.tsv`.

The nested-source build triage (`remaining-nested-license-build-triage-v4.tsv`)
now separates the 140 nested texts into 30 sample/test texts, 12 texts from
other gettext split packages, 27 other source components, six identified
runtime-component texts, and 65 texts still requiring build-component review.
All six identified runtime-component texts are present in the staged license
collection with exact SHA-256 matches
(`remaining-nested-runtime-staging-v2.tsv`). This includes the SLJIT text used
by PCRE2's enabled JIT; it was added with a backed-up manifest update. The
larger byte comparison (`remaining-nested-license-staging-v2.tsv`) finds 11 of
140 nested texts already staged. The other 129 must be judged against the
triage and build, rather than copied or excluded solely by filename. No source
index status was promoted by this triage alone.

Ten source-index rows were subsequently promoted in two reviewed batches.
The first six (`brotli`, `libffi`, `libunibreak`, `pixman`, `expat`, `lerc`)
have no package patches or nested license candidates; their source archives,
root license texts, PKGBUILD license staging, and shipped DLL imports were
checked. The next four (`pcre2`, `whisper.cpp`, `libtiff`, `libvpl`) were
checked against their build options, nested texts, patches where present,
shipped DLL hashes, and imports. PCRE2's enabled JIT uses the staged SLJIT
text. The libtiff patch changes the header install list; the three libvpl
patches change CMake/pkg-config installation metadata. The promotion scripts
under `packaging/tools/` retain pre-promotion source-index backups and write
`simple-six-source-verification-v1.tsv` and
`reviewed-four-source-verification-v1.tsv` in the Windows evidence directory.

`libpng` remains pending. Its MSYS2 package applies an APNG code patch. The
package recipe points to Mozilla's APNG patch, but the exact MSYS2 patch
(SHA-256 `a9c117324291cda7558ab36bec4ba28a34013d76e1ceaf9953749791a9e154a8`)
differs in code from both Mozilla's current patch and the 1.6.58 patch
distributed by the APNG project. The three patch files and their hashes are
retained under `libpng-apng-patch-provenance-v1/`. Trace the exact patch
revision and its license before promoting this row.

The release verifier also checks that every MSYS2 source-index package has one
matching license-manifest row and that its recorded text count equals the
number of staged files. This catches omissions when source-component notices
are added later.

The shipped `libshaderc_shared.dll` has the same SHA-256 as the DLL in the
MSYS2 `shaderc 2026.2-1` binary package. That package's `.BUILDINFO` pins
`glslang 16.2.0-3`, `spirv-tools 3~1.4.350.0-1`, and
`spirv-headers 2~1.4.350.0-1`. The currently installed glslang and
SPIRV-Tools packages are newer, so their files are not used as evidence for
this DLL. The exact historical MSYS2 source and binary archives, their
SHA-256 values, the upstream source hashes from `.SRCINFO`, and their original
license texts are retained under `shaderc-static-build-dependencies-v1/` and
`shaderc-static-dependency-verification-v1/` in the Windows evidence folder.
The three exact-version license texts were staged under shaderc's license
collection. The verifier checks those records and the ZIP includes the
verification table and shaderc `.BUILDINFO`. The DLL has no glslang or
SPIRV-Tools DLL imports and contains glslang 16.2.0 version strings; together
with the build recipe, this is evidence of code incorporated into shaderc's
DLL. Do not substitute current dependency versions when reviewing its source.

## Evidence To Freeze For a Release

For the exact build machine and build date, retain in the release repository or
release assets:

1. mpv source tag and commit; the current candidate uses `v0.41.0` /
   `41f6a645068483470267271e1d09966ca3b9f413`.
2. The Meson options, compiler version, Meson version, Ninja version, and build
   log.
3. The `ldd` output used to choose every copied DLL.
4. The output of `pacman -Q` and the owning MSYS2 package for every copied DLL.
5. Exact package archive names, versions, repository URLs, and SHA-256 values.
6. A manifest of every executable and DLL in the final ZIP, including SHA-256.

## Capture and Verify the Evidence

After `build-mpv-windows-msys2.sh` has assembled its portable runtime, capture
the source state, Meson configuration, MSYS2 package ownership, local license
texts, `ldd` reports, and runtime hashes in one new evidence directory:

```sh
MPV_TAG=v0.41.0 \
MPV_TEST_FILE=/c/path/to/approved-test.mp4 \
MPV_SOURCE_ARCHIVE_SHA256=<verified-mpv-source-sha256> \
WINDOWS_BUILD_EVIDENCE=docs/evidence/windows-msys2-v0.41.0-release \
packaging/scripts/build-mpv-windows-msys2.sh
```

For MSYS2 dependencies, the generated `source-index.tsv` prepopulates the
expected MSYS2 source-package URL. These source packages retain the PKGBUILD
and any MSYS2 patches in addition to the upstream source inputs. Download each
exact archive, record its SHA-256, inspect it for the expected package recipe,
and then change its status to `VERIFIED`. A candidate URL is not verification;
do not replace it with a current package page or a moving branch URL.

To download a selected set without changing its review status, run this from
the MSYS2 MINGW64 shell:

```sh
packaging/tools/collect-windows-msys2-source-packages.sh \
  /c/path/to/evidence \
  mingw-w64-x86_64-xvidcore mingw-w64-x86_64-x265
```

It writes immutable `.src.tar.zst` archives below `source-packages/` and their
hashes in `msys2-source-package-downloads.tsv`. Its status deliberately stays
`DOWNLOADED_NEEDS_REVIEW`; it is not release clearance.

Before detailed review, make a reproducible inventory of the downloaded
packages and save each PKGBUILD plus its archive file list:

```sh
packaging/tools/inspect-windows-msys2-source-packages.sh /c/path/to/evidence
```

The resulting `msys2-source-package-inspection.tsv` identifies declared
licenses, patch counts, nested upstream archives, and outer license candidates.
Every row remains `MECHANICAL_INSPECTION_NEEDS_LICENSE_REVIEW` until its
PKGBUILD, patches, source checksums, and actual license texts have been read.

The release verifier refuses a package when a runtime file is unowned, a local
license text is missing, or any source-index row remains unverified:

```sh
packaging/tools/verify-windows-selfbuild-evidence.sh \
  docs/evidence/windows-msys2-v0.41.0-release
```

## License and Source Deliverables

Before publishing, create a `documents/LICENSES/windows-selfbuild/` directory
in the ZIP containing:

- a machine-readable dependency manifest mapping every shipped DLL to its
  MSYS2 package, version, homepage/source URL, and declared license;
- the installed license text(s) for each relevant MSYS2 package;
- mpv's license and copyright files;
- a source index with exact, durable locations for the source archives used for
  mpv and every shipped dependency; and
- the project build and packaging scripts used for the release.

For GPL-covered binaries, provide the complete corresponding source with access
that is at least as easy as the binary download, or use another distribution
method permitted by the applicable GPL version. Merely linking to a current
upstream branch is not enough: the source must match the shipped binary.

The MSYS2 packaging policy records package license metadata and installs many
license texts under `<prefix>/share/licenses/<package>/`. Preserve these files
for the exact packages used, rather than inferring licenses from DLL filenames.

## Release Decision

The Windows v0.3.0 ZIP may be uploaded only after a reviewer confirms all of
the following:

- every runtime file is in the manifest;
- every runtime file has an identified package/source and license;
- required notices and license texts are in the ZIP;
- corresponding source access has been tested from the published locations;
- `NOTICE`, `LICENSES/source-and-build-info.txt`, and release notes identify
  the project-built Windows runtime rather than a third-party build; and
- the final ZIP's SHA-256 and the manifest's SHA-256 values match the uploaded
  asset.

For a project-built Windows release, pass the verified evidence to the
packager and make it mandatory:

```sh
VERSION=v0.3.0 \
WINDOWS_MPV_DIR=/c/work/codex/builds/mpv_r-v0.41.0-portable \
REQUIRE_WINDOWS_LICENSE_EVIDENCE=1 \
WINDOWS_LICENSE_EVIDENCE=docs/evidence/windows-msys2-v0.41.0-release \
packaging/scripts/build-windows.sh
```

The ZIP then includes the runtime and license manifests, source index, local
license texts, MSYS2 package metadata, linkage reports, source/build records,
build scripts, and a hash manifest for every final packaged `.exe`/`.dll` under
`documents/LICENSES/windows-selfbuild/`.

## References

- MSYS2 package licensing metadata:
  <https://www.msys2.org/dev/package-licensing/>
- MSYS2 mpv package metadata and source archive:
  <https://packages.msys2.org/packages/mingw-w64-x86_64-mpv>
- GNU GPL FAQ on corresponding source:
  <https://www.gnu.org/licenses/gpl-faq.en.html>
