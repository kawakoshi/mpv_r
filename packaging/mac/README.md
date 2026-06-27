# macOS Packaging Notes

v0.1.0 is packaged manually.

## Current v0.1.0 State

The published v0.1.0 Mac Preview is usable, but its package layout is older than
the Windows v0.1.1 package.

Known differences to clean up in v0.2:

- Japanese reference text files are still mixed into the package root.
- `source-and-build-info_jp.txt` is still under `LICENSES`.
- The package layout is not yet aligned with the Windows `translations_ja`
  convention.
- The packaging procedure is still manual.

## v0.2 Target Layout

v0.2 should align the Mac package with the Windows package convention:

```text
mpv_r-mac-v0.2.0/
  mpv_r.app
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

English files remain the authoritative texts. Japanese files are reference
translations and should be grouped under `translations_ja`.

## Manual Flow

1. Prepare `mpv_r.app`.
2. Include README, NOTICE, LICENSE, and LICENSES.
3. Add Japanese reference translations under `translations_ja`.
4. Create `mpv_r-mac-v0.2.0.zip`.
5. Run the macOS smoke test checklist.
6. Upload the zip to GitHub Releases.

## macOS Release Notes Checklist

Release notes should include:

- target macOS package name
- short description of what changed
- package contents
- ad-hoc signing and notarization status
- first-launch Gatekeeper note
- bundled mpv version and build source
- project affiliation disclaimer
- smoke test summary
- SHA256 checksum

Automation is planned after the manual flow is confirmed.
