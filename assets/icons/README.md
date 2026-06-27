# mpv_r Icons

`mpv_r-icon.svg` is the editable source for the mpv_r v0.x app icon.

This icon is the official icon for the `mpv_r` preview-era app. If the project
is renamed for a later full application, the renamed app should receive a new
icon instead of continuing this one unchanged.

Generated files:

- `mpv_r-icon-1024.png` - preview and source raster for generated icons
- `mpv_r-icon.icns` - macOS app icon
- `mpv_r-icon.ico` - Windows icon source for the launcher and future installer

Concept files under `concepts/` are retained as visual references. The A6
concept documents the current `mpv_r` icon direction, while the violet tone
tests are references for future renaming or commissioned icon work. They are
not used by the packaging scripts.

Regenerate the macOS icon:

```sh
packaging/tools/generate-mac-icon.sh
```

Regenerate the Windows icon:

```sh
packaging/tools/generate-windows-icon.sh
```

The macOS packaging script copies `mpv_r-icon.icns` into `mpv_r.app` when it is present.
The Windows packaging script embeds `mpv_r-icon.ico` into `mpv_r.exe` with
`goversioninfo` before building the Go launcher. If `goversioninfo` is not
installed, the script runs the pinned Go tool version with `go run`.
