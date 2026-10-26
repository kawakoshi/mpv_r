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

## References

- MSYS2 package licensing metadata:
  <https://www.msys2.org/dev/package-licensing/>
- MSYS2 mpv package metadata and source archive:
  <https://packages.msys2.org/packages/mingw-w64-x86_64-mpv>
- GNU GPL FAQ on corresponding source:
  <https://www.gnu.org/licenses/gpl-faq.en.html>
