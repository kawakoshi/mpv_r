# macOS v0.3.0 Runtime Audit Evidence

This directory records a forensic inventory of the already-published
`mpv_r-mac-v0.3.0.dmg`. It is not a declaration that the published DMG has a
complete third-party license or corresponding-source package.

## Asset

- DMG: `mpv_r-mac-v0.3.0.dmg`
- DMG SHA-256:
  `ea459df3693d9ca7791452c6adcec904c6832022520a68dec4e0b818b6cc10c8`
- Runtime inventory: `mpv` plus 42 bundled dylibs.

## Files

- `runtime-manifest.tsv` records each shipped executable or dylib, its
  SHA-256, and a Homebrew Keg/Formula candidate found during the audit.
- `linkage.txt` records `otool -L` output for every shipped executable or
  dylib.

## Interpretation

The app-bundling process relocates dylib install names and dependency paths.
That can change a dylib's bytes after it was copied from Homebrew, so a
`keg_content_match=no` row does not itself prove a different source package.
For this already-published asset, a pre-relocation Keg manifest was not saved;
therefore, the audit can identify likely Formula/Keg provenance but cannot
retroactively prove byte-for-byte input identity for relocated files.

The retained Homebrew Kegs and bottle manifests preserve useful evidence for
the principal build inputs, including mpv 0.41.0_6, FFmpeg 8.1.2, x264 r3222,
x265 4.2, and MoltenVK 1.4.1. Before publishing any replacement, preserve the
exact source archives, Formula revisions, license texts, and pre-/post-
relocation manifests described in `docs/mac-selfbuild-license-audit.md`.
