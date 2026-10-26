# macOS v0.3.0 Build Reconstruction Record

This is a reconstruction from retained repository documents and the published
DMG. It is deliberately not described as the original build log.

## Published Asset

- DMG: `mpv_r-mac-v0.3.0.dmg`
- DMG SHA-256:
  `ea459df3693d9ca7791452c6adcec904c6832022520a68dec4e0b818b6cc10c8`
- target: Apple Silicon (`arm64`)

## mpv Source

- upstream repository: `https://github.com/mpv-player/mpv`
- recorded tag: `v0.41.0`
- tag commit: `41f6a645068483470267271e1d09966ca3b9f413`
- verified source archive:
  `https://github.com/mpv-player/mpv/archive/41f6a645068483470267271e1d09966ca3b9f413.tar.gz`
- archive SHA-256:
  `068960e89211f2adc80af03f637fa393fb5e407d3dd23592c8fe8c5490bb7ae4`

The tag commit and archive checksum were verified during this audit. The
published runtime manifest identifies the bundled executable as this source
build, but does not prove a byte-for-byte relationship because the original
pre-package build directory was not retained.

## Retained Procedure and Inputs

`docs/build-mpv-macos-arm64.md` records the Meson options used for the first
successful arm64 build and the `macos-bundle` target. `packaging/scripts/build-mac.sh`
records the subsequent packaging operations: copy `mpv.app`, inject mpv_r
configuration and documents, set the mpv_r bundle metadata, ad-hoc sign, and
create the DMG. The runtime Formula versions, Formula evidence, license texts,
and primary source archives are catalogued in:

- `runtime-manifest.tsv`
- `homebrew-license-collection/formula-manifest.tsv`
- `homebrew-license-collection/homebrew-formula-index.tsv`
- `homebrew-license-collection/primary-source-index.tsv`

## Facts Not Retained for v0.3.0

The original mpv checkout/build directory is no longer present. No
contemporaneous Meson introspection files, compiler versions, Homebrew lockfile,
pre-relocation Keg manifest, complete patch/resource record, package command
log, or packaging-repository commit was saved with the release. Therefore this
record narrows the inputs but does not make the already-published DMG a fully
reproducible or corresponding-source-complete release.

For the next Mac release, collect those facts before packaging and retain the
pre- and post-relocation manifests specified in
`docs/mac-selfbuild-license-audit.md`.
