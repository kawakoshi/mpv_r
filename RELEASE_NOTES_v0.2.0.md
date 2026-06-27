# mpv_r v0.2.0 - Package Cleanup

v0.2.0 aligns the Mac and Windows packages so both platforms follow the same
documentation and translation layout.

Japanese reference translation:

- `translations_ja/RELEASE_NOTES_v0.2.0_jp.md`

## Download

Download:

- `mpv_r-mac-v0.2.0.zip`
- `mpv_r-windows-v0.2.0.zip`

Use the attached app zip under Release assets. Do not download GitHub's
automatic `Source code (zip)` if you want to run the app.

## What's Changed

- Align Mac and Windows package layouts.
- Use the same top-level package shape on both platforms: launcher/app,
  `resources`, and `documents`.
- Group Japanese reference translations under `documents/translations_ja`.
- Keep English README, NOTICE, LICENSE, and LICENSES under `documents`.
- Add smoke test checklists for release verification.
- Keep the app behavior compatible with v0.1.x unless explicitly noted.

## What's Included

Mac package:

- `mpv_r.app`
- `resources/config` with the renewed `mpv_r` configuration files
- `documents` with README, install notes, Japanese reference translations,
  mpv license texts, and source/build links

Windows package:

- `mpv_r.exe`
- bundled `resources/mpv/mpv.exe`
- `resources/config` with the renewed `mpv_r` configuration files
- `documents` with README, install notes, Japanese reference translations,
  mpv license texts, and source/build links

The Windows package does not bundle mpv's upstream `doc/manual.pdf` or
`doc/mpbindings.png`; mpv documentation is linked from NOTICE/source information.

## Notes

- This is a preview release.
- The Mac app is ad-hoc signed but not notarized.
- On first Mac launch, right-click the app and choose `Open`.
- The Windows launcher is not code-signed. Windows SmartScreen behavior may vary.
- This project is not affiliated with mpv-player or the bundled mpv build providers.

## Smoke Test

Before publishing, run the platform smoke test checklists:

- `docs/smoke-test-mac.md`
- Windows checklist: to be added

## Checksum

SHA256:

```text
dcc5a9498eff9d2e68e976e0c79f9160db4688fe680361c5b308b298d519232e  mpv_r-mac-v0.2.0.zip
77c5d19a533cf5d23a88e0c076d1eec10ec0d425337cb165b69590ad6f369eba  mpv_r-windows-v0.2.0.zip
```
