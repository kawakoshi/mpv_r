# Windows Packaging Notes

v0.1.1 uses a small Go launcher:

- source: `cmd/mpv-r-launcher/main.go`
- output: `mpv_r.exe`

The launcher starts the bundled `mpv/mpv.exe` with:

```text
--config-dir=portable_config
```

and passes through all file arguments.

## Build

```sh
GOCACHE="$PWD/build/go-cache" GOOS=windows GOARCH=amd64 go build -ldflags "-H windowsgui" -o build/windows/mpv_r.exe ./cmd/mpv-r-launcher
```

`-H windowsgui` prevents a console window from appearing when the launcher is started from Explorer.

## Expected Package Layout

```text
mpv_r-windows-v0.1.1/
  mpv_r.exe
  mpv/
    mpv.exe
    mpv.com
    d3dcompiler_43.dll
    mpv/
      fonts.conf
    doc/
      manual.pdf
      mpbindings.png
  portable_config/
    mpv.conf
    input.conf
  README.txt
  README_jp.txt
  NOTICE.txt
  NOTICE_jp.txt
  LICENSE.txt
  LICENSE_jp.txt
  LICENSES/
```
