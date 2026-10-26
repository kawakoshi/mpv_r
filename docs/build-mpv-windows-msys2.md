# Build mpv for Windows x64 with MSYS2

Japanese reference translation:

- `../translations_ja/build-mpv-windows-msys2_jp.md`

## Purpose

This procedure builds a project-controlled Windows x64 mpv runtime and gathers
the MINGW64 DLLs it needs into a portable folder. It does not create an
installer and does not sign any executable.

Run it on Windows from an MSYS2 **MINGW64** shell. Do not use the plain MSYS
shell or a Command Prompt for the Meson build.

## First Verified Build

The first clean, portable build was verified on 2026-10-26:

- source tag and commit: `v0.41.0` / `41f6a645068483470267271e1d09966ca3b9f413`
- environment: MSYS2 MINGW64, GCC 16.1.0, Meson 1.11.1, Ninja 1.13.2
- target: Windows x64
- enabled output paths included D3D11, Vulkan, WASAPI, libmpv, FFmpeg,
  libplacebo, libass, LuaJIT, JPEG, shaderc, and zimg
- portable runtime: 116 files (`mpv.exe`, `mpv.com`, and 114 DLLs), about
  197 MB
- portable validation: `mpv.exe --no-config --no-audio --vo=null` decoded a
  local H.264 test video to end while `PATH` excluded `/mingw64/bin`

The runtime file count is expected to change when MSYS2 packages change. Do not
maintain a hand-written DLL list; derive it from `ldd` for each build.

## Prerequisites

- Windows x64
- MSYS2 with the MINGW64 toolchain and the dependencies needed by mpv
- Git, Meson, Ninja, and `ldd` available in the MINGW64 shell
- Network access to clone `https://github.com/mpv-player/mpv.git` on the first
  run

The upstream mpv CI workflow is the reference for a current MSYS2 dependency
set. Keep this project's build pinned to a released mpv tag rather than using
an arbitrary upstream development commit.

## Build And Collect Runtime Files

From the `mpv_r` repository in an MSYS2 MINGW64 shell:

```sh
MPV_TAG=v0.41.0 \
MPV_TEST_FILE=/c/path/to/approved-test.mp4 \
packaging/scripts/build-mpv-windows-msys2.sh
```

Default locations are:

```text
/c/work/codex/repos/mpv-r-upstream-v0.41.0
/c/work/codex/builds/mpv_r-v0.41.0-portable
```

The script refuses to use a source checkout with uncommitted changes and
refuses to overwrite an existing portable output directory. This protects the
recorded build from accidental mixing with a previous test.

The output folder contains `mpv.exe`, `mpv.com`, `libmpv-2.dll`, every DLL
reported under `/mingw64` by `ldd`, and `FILELIST.txt`. System DLLs under
`C:\Windows` are intentionally not copied.

## Validation

The script first runs `mpv.exe --version` with a PATH limited to the portable
folder and `C:\Windows\System32`. When `MPV_TEST_FILE` is provided, it then
decodes the file with a null video output. Run the separate Windows smoke test
after packaging `mpv_r` around this runtime.

## Packaging Input

Pass the generated runtime folder to the Windows package script:

```sh
WINDOWS_MPV_DIR=/c/work/codex/builds/mpv_r-v0.41.0-portable \
packaging/scripts/build-windows.sh
```

The package script copies executable and DLL runtime files from that folder.
It does not use the old third-party mpv binary layout.
