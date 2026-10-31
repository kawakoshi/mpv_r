# Windows Packaging Notes

Windows v0.3.0 uses a small Go launcher and a
portable ZIP package; it is not an installer.

- source: `cmd/mpv-r-launcher/main.go`
- output: `mpv_r.exe`

The launcher starts the bundled `resources/mpv/mpv.exe` with:

```text
--config-dir=resources/config
```

and passes through all file arguments.

The portable package also includes `register-file-associations.cmd`. It runs a
current-user PowerShell registration script that exposes `mpv_r` in Windows
Default apps and supplies its executable icon for selected video types. It
does not write `UserChoice` or force a default association.

`create-desktop-shortcut.cmd` creates a current-user Desktop shortcut that
targets the extracted `mpv_r.exe`, uses its icon, and keeps the package folder
as its working directory. Dragging video files onto this shortcut is the
recommended portable-package workflow. Moving the extracted package afterwards
breaks the shortcut until it is created again.

## Build

```sh
packaging/scripts/build-windows.sh
```

`-H windowsgui` prevents a console window from appearing when the launcher is started from Explorer.

For the next project-built mpv runtime, first run:

```sh
MPV_TAG=v0.41.0 packaging/scripts/build-mpv-windows-msys2.sh
```

Then provide its portable output through `WINDOWS_MPV_DIR` when running
`build-windows.sh`. The package script copies every `.exe` and `.dll` in that
runtime folder, plus `mpv.com`, rather than relying on a fixed third-party mpv
file list. When verified license evidence is supplied, the completed ZIP is
also extracted and checked against both the captured runtime manifest and the
final package manifest before the build is reported as successful.

## User Documentation

The current Windows user guide is:

- `docs/windows-preview-guide.md`

It covers extraction, normal startup, SmartScreen, keeping the portable package
together, review controls, screenshots, and recovery of the supplied settings.

## v0.3 Layout

```text
mpv_r/
  mpv_r.exe
  resources/
    mpv/
      mpv.exe
      mpv.com
      libmpv-2.dll
      *.dll (runtime dependencies from `ldd`, plus dynamically loaded ggml CPU backends)
      mpv/
        fonts.conf (only when provided by the runtime source)
    config/
      mpv.conf
      input.conf
  documents/
    README.txt
    NOTICE.txt
    LICENSE.txt
    LICENSES/
      mpv-Copyright.txt
      mpv-LICENSE.GPL.txt
      mpv-LICENSE.LGPL.txt
      source-and-build-info.txt
    translations_ja/
      README_jp.txt
      NOTICE_jp.txt
      LICENSE_jp.txt
      source-and-build-info_jp.txt
```

The upstream mpv `doc/manual.pdf` and `doc/mpbindings.png` files are not bundled
in v0.3. mpv documentation is linked from NOTICE/source information instead.
