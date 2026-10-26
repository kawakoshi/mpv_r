# macOS Packaging Notes

## v0.3.0 Mac Preview

v0.3.0 is a Mac-only Apple Silicon Preview. It is distributed as a DMG:

```text
mpv_r.app
Applications -> /Applications
```

The application bundle contains the review configuration and project documents:

```text
mpv_r.app/Contents/Resources/
  mpv.conf
  input.conf
  documents/
```

English documents are authoritative. Japanese files under
`documents/translations_ja` are reference translations.

## Build

Use the documented project-built arm64 `mpv.app` as input:

```sh
VERSION=v0.3.0 \
BUILD_DMG=1 \
MAC_SOURCE_APP=/path/to/mpv.app \
packaging/scripts/build-mac.sh
```

The script ad-hoc signs `mpv_r.app`, creates a DMG, and prints SHA-256 values.
The output is not notarized. Apple Silicon / arm64 is the only v0.3.0 target.

## Release Checklist

1. Run `docs/smoke-test-mac.md` against the final DMG.
2. Record the final DMG SHA-256 in `RELEASE_NOTES_v0.3.0.md`.
3. Publish only `mpv_r-mac-v0.3.0.dmg` for this release; Windows remains at
   v0.2.0.
