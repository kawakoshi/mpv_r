# mpv_r

`mpv_r` is a macOS video review player based on mpv.

It is a renewed distribution of the author's old `mpv_r` setup for frame-by-frame review, quick playback checks, playlist review, and screenshots.

This v0.1.0 release is a Mac Preview. A Windows Preview is planned for v0.1.1.

## Download

Download the app zip from GitHub Releases:

- `mpv_r-mac-v0.1.0.zip`

Do not download GitHub's automatic `Source code (zip)` archive if you want the app. Use the zip attached under Release assets.

## Install on macOS

1. Download `mpv_r-mac-v0.1.0.zip`.
2. Unzip it.
3. Move `mpv_r.app` to `/Applications`.
4. On first launch, right-click `mpv_r.app` and choose `Open`.
5. If macOS shows a warning, choose `Open` again.

The first launch may require right-clicking because this preview is not notarized.

## Open Videos

- Drag one or more video files onto `mpv_r.app`.
- Or right-click a video file and choose `Open With` -> `mpv_r`.

Multiple files are loaded as a playlist.

## Basic Controls

This preview keeps the original `mpv_r` style controls.

- `Space` / `0` on numpad: play or pause
- `Left` / `Right`: previous or next frame
- `Up` / `Down`: previous or next file
- `Shift + Left` / `Shift + Right`: seek 1 second
- `Shift + Up` / `Shift + Down`: seek 30 seconds
- `/`: screenshot
- `f` / `*`: fullscreen
- `Esc`: exit fullscreen
- `Command + W` / `Control + W`: quit

Screenshots are saved to the Desktop using the file name and timecode.

## Included mpv Build

This release bundles mpv `0.39.0` for macOS using the unofficial third-party macOS build by stolendata, linked from the mpv installation page:

- https://mpv.io/installation/
- https://laboratory.stolendata.net/~djinn/mpv_osx/

This project is not affiliated with mpv-player or stolendata.

See `NOTICE.md` and `LICENSES/` for license and attribution details.

## Source Configuration

The bundled configuration is kept in:

- `config/mac/mpv.conf`
- `config/mac/input.conf`

## Roadmap

- v0.1.0: Mac Preview
- v0.1.1: Windows Preview
- v0.2: packaged docs, license bundle, icon, release flow cleanup
- v0.3: self-build investigation for mpv
- v1.0: first Stable/LTS release

