# Windows Packaging Notes

The current Windows release is v0.2.0. It uses a small Go launcher and a
portable ZIP package; it is not an installer.

- source: `cmd/mpv-r-launcher/main.go`
- output: `mpv_r.exe`

The launcher starts the bundled `resources/mpv/mpv.exe` with:

```text
--config-dir=resources/config
```

and passes through all file arguments.

## Build

```sh
packaging/scripts/build-windows.sh
```

`-H windowsgui` prevents a console window from appearing when the launcher is started from Explorer.

## User Documentation

The current Windows user guide is:

- `docs/windows-preview-guide.md`

It covers extraction, normal startup, SmartScreen, keeping the portable package
together, review controls, screenshots, and recovery of the supplied settings.

## v0.2 Target Layout

```text
mpv_r/
  mpv_r.exe
  resources/
    mpv/
      mpv.exe
      mpv.com
      d3dcompiler_43.dll
      mpv/
        fonts.conf
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
in v0.2. mpv documentation is linked from NOTICE/source information instead.
