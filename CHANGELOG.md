# Changelog

## v0.1.1 - Windows Preview

Initial public preview for Windows 64-bit.

- Bundles the shinchiro Windows x86_64 build of mpv.
- Adds a small Go launcher, `mpv_r.exe`, for a simpler Windows entry point.
- Uses `portable_config` so the bundled review configuration stays with the app folder.
- Includes the renewed `mpv_r` keyboard controls based on the Mac v0.1.0 configuration.
- Saves screenshots to the user's Desktop.
- Includes mpv license files, copyright notice, and source/build links.

Smoke test notes:

- Confirmed on Windows: launch works, no console window appears, video opens, primary key controls work, and screenshots save to the Desktop.
- Windows SmartScreen did not block the first manual test, but behavior may vary because the launcher is not code-signed.

## v0.1.0 - Mac Preview

Initial public preview for macOS.

- Bundles mpv `0.39.0` using the unofficial stolendata macOS build.
- Includes the renewed `mpv_r` configuration for review-oriented playback.
- Supports file drag-and-drop onto `mpv_r.app`.
- Opens multiple files as a playlist.
- Starts paused and keeps the window open after playback ends.
- Saves screenshots to the Desktop.
- Includes mpv license files, copyright notice, and source links.

Known notes:

- The app is ad-hoc signed but not notarized.
- On first launch, macOS may require right-clicking the app and choosing `Open`.
- Windows support is planned for v0.1.1.
