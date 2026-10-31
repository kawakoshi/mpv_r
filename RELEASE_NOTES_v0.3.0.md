# mpv_r v0.3.0 - Project-Built Mac and Windows Preview

v0.3.0 provides project-built mpv v0.41.0 runtimes for Apple Silicon Mac and
64-bit Windows. Mac uses a DMG; Windows uses a portable ZIP.

Japanese reference translation:

- `translations_ja/RELEASE_NOTES_v0.3.0_jp.md`

## Download

Download:

- `mpv_r-mac-v0.3.0.dmg`
- `mpv_r-windows-v0.3.0.zip`
- `mpv_r-windows-v0.3.0-corresponding-source.tar.zst`

Use the attached app package under Release assets. Do not download GitHub's
automatic `Source code (zip)` if you want to run the app.

## What's Changed

- Mac Preview is now packaged as a DMG.
- The Mac DMG contains `mpv_r.app` and an `Applications` shortcut.
- Mac documents, notices, license texts, and Japanese reference translations are
  included inside `mpv_r.app`.
- Mac Preview now uses a project-built Apple Silicon mpv v0.41.0 bundle.
- The Mac app keeps the provisional mpv_r icon introduced during v0.2 work.
- Windows now uses a project-built MSYS2 MINGW64 mpv v0.41.0 runtime.
- The Windows ZIP includes Desktop-shortcut and current-user file-association commands.
- The Windows ZIP includes runtime/source/license manifests and 163 staged license files.
- A separate corresponding-source asset preserves the exact 86 MSYS2 source packages, mpv source, patches, and build records used for the Windows runtime.

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

- Windows 64-bit is the target for v0.3.0.
- Extract the portable ZIP as a complete folder; it is not an installer.
- Use the supplied command to create a Desktop shortcut, then drag videos onto it.
- The launcher and bundled mpv are not code-signed, so SmartScreen or Smart App Control may warn or block them.
- Continue only for files downloaded from this project's Release assets after checking the published SHA-256.

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

Windows ZIP:

- `mpv_r.exe` launcher
- project-built mpv v0.41.0 runtime and DLLs
- Desktop-shortcut and file-association commands
- bundled English documents and Japanese reference translations
- runtime, source, license, and final-package verification records

## Notes

- This is a preview release.
- This project is not affiliated with mpv-player or the bundled mpv build
  providers.

## Checksum

SHA256:

```text
ea459df3693d9ca7791452c6adcec904c6832022520a68dec4e0b818b6cc10c8  mpv_r-mac-v0.3.0.dmg
23c75c83d05e4b52707b0fda2962b6b9189b755a9917004a31ceb2d01b9845a0  mpv_r-windows-v0.3.0.zip
ea4c4df1c3f62e9401b96cb22ef4208de64e13ed3f428d3a588d3961c85c8010  mpv_r-windows-v0.3.0-corresponding-source.tar.zst
```
