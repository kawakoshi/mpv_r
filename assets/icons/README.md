# mpv_r Icons

`mpv_r-icon.svg` is the editable source for the v0.2 app icon.

Generated files:

- `mpv_r-icon-1024.png` - preview and source raster for generated icons
- `mpv_r-icon.icns` - macOS app icon
- `mpv_r-icon.ico` - Windows icon source for the launcher or future installer

Regenerate the macOS icon:

```sh
packaging/tools/generate-mac-icon.sh
```

Regenerate the Windows icon:

```sh
packaging/tools/generate-windows-icon.sh
```

The macOS packaging script copies `mpv_r-icon.icns` into `mpv_r.app` when it is present.
