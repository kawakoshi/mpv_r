# Windows MSYS2 mpv v0.41.0 self-build evidence

This folder stores evidence from the first successful Windows self-build trial
for mpv_r.

## Result

- Host environment: Windows, MSYS2 MINGW64
- mpv source version: `v0.41.0`
- Build system: Meson `1.11.1`, Ninja `1.13.2`
- Compiler: GCC `16.1.0` from MSYS2
- Build result: `build/mpv.exe` and `build/mpv.com` were generated
- Runtime result: `mpv.exe` played a local test video from the MSYS2 environment
- Portable test result: DLLs reported by `ldd build/mpv.exe` were copied into a
  portable test folder, and playback worked from that folder

## Files

- `meson-log.txt`: Meson setup log from `C:/Users/localadmin/Documents/mpv/build/meson-logs/meson-log.txt`
- `ninja-log.txt`: Ninja build log from `C:/Users/localadmin/Documents/mpv/build/.ninja_log`
- `ldd-mpv-exe.txt`: `ldd build/mpv.exe` output
- `portable-test-files.txt`: file listing of the portable test folder
- `mpv-version.txt`: `mpv v0.41.0-dirty` runtime version output
- `msys2-installer-note.txt`: incidental MSYS2 installer log; kept only as context

## Notes

- The initial Windows command prompt path was not suitable for Meson/MSYS2
  commands. The successful build used the MSYS2 `MINGW64` shell.
- Pasting commands from Discord's copy button inserted bracketed-paste control
  text in the terminal during this trial. Manual selection or a plain-text
  intermediate is safer.
- Running `mpv.com` with a media file returned `Permission denied` during the
  trial, while `mpv.exe` played the same file.
- Explorer direct launch requires the runtime DLLs to be colocated with
  `mpv.exe`, or otherwise discoverable in `PATH`.

