# mpv_r v0.3.0 - Mac Apple Silicon DMG Preview

v0.3.0 updates the Mac Preview package to a self-built Apple Silicon mpv bundle
and introduces a DMG-style Mac installation flow.

Japanese reference translation:

- `translations_ja/RELEASE_NOTES_v0.3.0_jp.md`

## Download

Download:

- `mpv_r-mac-v0.3.0.dmg`

Use the attached app package under Release assets. Do not download GitHub's
automatic `Source code (zip)` if you want to run the app.

## What's Changed

- Mac Preview is now packaged as a DMG.
- The Mac DMG contains `mpv_r.app` and an `Applications` shortcut.
- Mac documents, notices, license texts, and Japanese reference translations are
  included inside `mpv_r.app`.
- Mac Preview now uses a project-built Apple Silicon mpv v0.41.0 bundle.
- The Mac app keeps the provisional mpv_r icon introduced during v0.2 work.
- Windows remains on the separately released v0.2.0 portable zip package.

## Platform Notes

Mac:

- Apple Silicon Macs are the target for v0.3.0.
- Intel Mac is not a v0.3.0 target. Intel Mac users should use an existing mpv
  build or an earlier mpv_r preview package.
- The Mac app is ad-hoc signed but not notarized.
- On first launch, right-click `mpv_r.app` and choose `Open` if macOS blocks it.
- If macOS later blocks a trusted downloaded video by filename, use `System
  Settings` > `Privacy & Security` > `Open Anyway` for that specific video and
  authenticate when prompted.

Windows:

- No Windows v0.3.0 package is released with this Mac-only release.
- The currently published Windows package remains v0.2.0.
- Windows documentation and packaging improvements will be prepared separately.

## Documents

Project documents are available in two places:

- GitHub repository documents
- The bundled app package

On Mac, bundled documents are stored inside:

```text
mpv_r.app/Contents/Resources/documents/
```

This keeps the DMG simple for users while preserving README, NOTICE, license,
source/build, shortcut, and Japanese reference translation files in the app
bundle.

## What's Included

Mac DMG:

- `mpv_r.app`
- `Applications` shortcut
- bundled `documents` inside `mpv_r.app`
- renewed `mpv_r` configuration files inside `mpv_r.app`

## Notes

- This is a preview release.
- This project is not affiliated with mpv-player or the bundled mpv build
  providers.

## Checksum

SHA256:

```text
ea459df3693d9ca7791452c6adcec904c6832022520a68dec4e0b818b6cc10c8  mpv_r-mac-v0.3.0.dmg
```
