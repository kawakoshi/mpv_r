# macOS Self-Build Release License Audit

This is the macOS equivalent of the Windows self-build release gate.

## Status of the Published v0.3.0 DMG

The published Apple Silicon DMG contains `mpv` and 42 bundled dynamic
libraries, including FFmpeg, x264, x265, OpenSSL, and MoltenVK. Its current
documents identify mpv but do not yet provide a complete per-library manifest,
license set, or corresponding-source index. Do not treat the documentation as
complete licensing evidence for a subsequent Mac release.

The v0.3.0 build used Homebrew-provided dependencies. Homebrew Formulae change
over time, so current Formula pages cannot be substituted for the Formula and
source revisions that produced the published binary.

## Evidence

For every Mac release, run:

```sh
packaging/tools/audit-macos-runtime.sh \
  /path/to/mpv_r.app \
  docs/evidence/macos-runtime-vX.Y.Z
```

Commit the generated `runtime-manifest.tsv` and `linkage.txt` before publishing.
The manifest records the bundled file hash, matching Homebrew Keg path, Formula,
and Formula version. The `mpv` executable is a source build, not a Homebrew
Keg; set `MPV_SOURCE_TAG` when running the tool to record its upstream tag.
`keg_content_match=no` is expected when the app-bundling
step rewrites a dylib's install name or dependency paths. It is not, by itself,
proof that the source package is wrong. For a new release, record a manifest
both before and after relocation so that the pre-relocation Keg hash proves the
input and the post-relocation hash proves the shipped file. An `UNMAPPED` row,
or an unexplained pre-relocation mismatch, blocks release.

## Release Deliverables

Before publishing a replacement Mac DMG, include or link with equivalent access
to all of the following:

- a manifest for `mpv` and every bundled dylib;
- a pre-relocation Keg manifest and a post-relocation shipped-file manifest;
- license and notice texts for the identified upstream packages;
- exact source archives, source revisions, patches, and build instructions for
  GPL/LGPL-covered components; and
- the Homebrew Formula revision and bottle/Keg evidence used at build time.

This review also applies to codec patent considerations separately from open
source license compliance.

## Homebrew License Collection

After generating the runtime manifest, collect the license texts and retained
Homebrew evidence without overwriting an existing collection:

```sh
packaging/tools/collect-macos-homebrew-licenses.sh \
  docs/evidence/macos-runtime-vX.Y.Z/runtime-manifest.tsv \
  docs/evidence/macos-runtime-vX.Y.Z/homebrew-license-collection
```

The collection copies license/copyright/notice files and installation receipts
from the exact local Kegs identified in the manifest. It also copies a cached
Homebrew bottle manifest when available. A missing bottle manifest is evidence
to resolve, not permission to substitute current Formula metadata.

Generate a Formula-revision index from the retained bottle manifests:

```sh
packaging/tools/generate-macos-homebrew-formula-index.sh \
  docs/evidence/macos-runtime-vX.Y.Z/homebrew-license-collection \
  docs/evidence/macos-runtime-vX.Y.Z/homebrew-license-collection/homebrew-formula-index.tsv
```

The resulting Formula URL and commit identify the exact Homebrew recipe. The
upstream source archive URL and checksum still need to be extracted from that
revision before a release can claim corresponding-source readiness.

`macos-runtime-v0.3.0/homebrew-license-collection/primary-source-index.tsv`
records the primary upstream archive and SHA-256 now identified for each
Formula in the published v0.3.0 runtime. It is audit evidence, not a release
clearance: the build's patches, auxiliary resources, configure flags, and the
exact build environment must still be retained and checked for the next DMG.
Rows whose retained bottle did not expose an immutable Formula revision say so
explicitly; their upstream archive is verified but cannot prove the original
Homebrew recipe on its own.
