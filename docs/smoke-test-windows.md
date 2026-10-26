# Windows Smoke Test

Japanese reference translation:

- `../translations_ja/smoke-test-windows_jp.md`

Run this checklist before rebuilding or replacing a Windows preview package.

## Package

- Extract the release ZIP.
- Confirm `mpv_r.exe`, `resources/mpv`, `resources/config`, and `documents`
  are present.
- For a project-built runtime, confirm `resources/mpv/mpv.exe`,
  `resources/mpv/libmpv-2.dll`, and the DLL set derived from `ldd` are present.
- Confirm `documents/windows-preview-guide.md` and its Japanese reference
  translation are present.

## Launch And Playback

- Start `mpv_r.exe` from its extracted folder.
- Confirm the bundled `resources/mpv/mpv.exe --version` matches the documented
  project-built mpv tag.
- Open one video file.
- Drag and drop a video file onto `mpv_r.exe`.
- Open multiple video files and confirm playlist navigation.
- Confirm play/pause, frame forward/backward, previous/next file, and
  fullscreen controls.

## Screenshot And Paths

- Capture a screenshot and confirm it is saved to the signed-in user's Desktop.
- Test a path containing spaces.
- Test a filename containing Japanese characters.

## Portable Layout

- Confirm the launcher displays an understandable error when `resources/mpv`
  is missing.
- Restore the complete package and confirm normal launch again.
- Confirm playback after starting from the extracted folder, with no MSYS2
  runtime directory added to PATH.

## Release Notes

- Confirm the package version and SHA-256 are documented.
- Confirm the SmartScreen and unsigned-launcher notice is documented.
