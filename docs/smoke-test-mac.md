# macOS Smoke Test

Japanese reference translation:

- `../translations_ja/smoke-test-mac_jp.md`

Run this checklist before publishing a Mac preview or stable package.

## Package

- Download or copy the release zip.
- Extract the zip.
- Confirm the package contains `mpv_r.app`, `README.txt`, `NOTICE.txt`,
  `LICENSE.txt`, `LICENSES`, and `translations_ja`.
- Confirm Japanese reference files are only under `translations_ja`.

## First Launch

- Move `mpv_r.app` to `/Applications` if testing the normal user flow.
- Launch with right-click -> `Open` when Gatekeeper blocks normal launch.
- Confirm the app launches without requiring additional setup files.

## Playback

- Open a single video file.
- Drag and drop a video file onto `mpv_r.app`.
- Open multiple video files and confirm they are treated as a playlist.
- Confirm playback and pause work.
- Confirm frame forward and frame backward work.
- Confirm previous/next file navigation works.

## Screenshot

- Capture a screenshot.
- Confirm the screenshot is saved to the Desktop.
- Confirm the filename is understandable.

## Path And File Names

- Test a file with spaces in the path.
- Test a file with Japanese characters in the name.

## Release Notes

- Confirm bundled mpv version and build source are documented.
- Confirm signing and notarization status are documented.
- Confirm SHA256 checksum is listed.
