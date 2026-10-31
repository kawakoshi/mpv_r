# Windows Preview Guide

Japanese reference translation:

- `../translations_ja/windows-preview-guide_jp.md`

## Scope

The Windows v0.3.0 release is a portable 64-bit ZIP package,
not an installer. Keep the extracted folder together; no setup program or
administrator permission is required for normal use.

## Start

1. Download `mpv_r-windows-v0.3.0.zip` from GitHub Releases. Do not use
   GitHub's automatic `Source code (zip)` archive.
2. Extract the ZIP to a writable folder such as `Documents` or `Downloads`.
3. Open the extracted `mpv_r` folder.
4. Start `mpv_r.exe`, or drag one or more video files onto `mpv_r.exe`.

Multiple files are loaded as a playlist. mpv_r opens paused by default.

## Recommended: Drag Videos onto a Desktop Shortcut

Double-click `create-desktop-shortcut.cmd` in the extracted package. It creates
an `mpv_r` shortcut on the current user's Desktop without changing any Windows
file association. Drag one or more video files onto that shortcut to open them
in mpv_r. Keep the complete extracted package in place after creating it.

## Show the mpv_r Icon and Choose It as a Default App

The portable ZIP does not change Windows file associations by itself. To add
mpv_r as a selectable video app (and give its selected file types the mpv_r
icon), double-click `register-file-associations.cmd` in the extracted package.
It needs no administrator permission and registers only for the current Windows
user.

Then open **Settings > Apps > Default apps**, choose **mpv_r**, and assign the
file types you want, such as `.mp4`. This script never changes the current
default app on its own. Keep the complete extracted `mpv_r` folder in place;
moving only `mpv_r.exe` later will break the registered command and icon.

## Keep the Package Together

`mpv_r.exe` starts the bundled player at `resources/mpv/mpv.exe` and loads
settings from `resources/config`. Do not move only `mpv_r.exe`; move or copy
the complete extracted `mpv_r` folder instead.

```text
mpv_r/
  mpv_r.exe
  resources/
    mpv/
    config/
  documents/
  create-desktop-shortcut.cmd
  register-file-associations.cmd
  tools/
    create-desktop-shortcut.ps1
    register-file-associations.ps1
```

## Review Controls

| Key | Action |
| --- | --- |
| `Space` or numpad `0` | Play / pause |
| Left / Right | Previous / next frame |
| Up / Down | Previous / next file in the playlist |
| `Shift` + Left / Right | Seek 1 second backward / forward |
| `Shift` + Up / Down | Seek 30 seconds backward / forward |
| `/` | Save a PNG screenshot to the Desktop |
| `f` or `*` | Toggle fullscreen |
| `Esc` | Leave fullscreen |
| `Ctrl` + `W` | Quit |

The full configuration is in `resources/config`. The packaged shortcut list is
`documents/shortcuts.md`.

## Windows Security Notices

The launcher is not code-signed. Windows may display a SmartScreen warning.
Continue only when the file was downloaded from the project's GitHub Releases
page and its published SHA-256 checksum matches the downloaded ZIP.

## Troubleshooting

- **"mpv executable not found"** — restore the complete extracted `mpv_r`
  folder; do not run an isolated copy of `mpv_r.exe`.
- **A video does not open** — start `mpv_r.exe` first and use its Open command,
  or drag the file onto the executable. Try a local file path without special
  permission restrictions.
- **No screenshot appears** — screenshots are PNG files saved to the signed-in
  user's Desktop with the source filename and timecode.
- **Settings need to be reset** — restore the original
  `resources/config/mpv.conf` and `resources/config/input.conf` from a fresh
  extracted package.

## Limitations

- Windows 64-bit only.
- This is a preview release.
- This project is not affiliated with mpv-player or shinchiro. License and
  source/build information are included under `documents`.
