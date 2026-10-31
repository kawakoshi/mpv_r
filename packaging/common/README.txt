mpv_r
=====

mpv_r is a video review player for Mac and Windows.

It packages mpv with the author's review-oriented settings so video files can
be checked frame by frame, compared across adjacent files, and captured as
screenshots with minimal setup.

Start
-----

Mac:

1. Open the DMG.
2. Drag `mpv_r.app` to `Applications`.
3. Open `mpv_r.app`.
4. On first launch, right-click `mpv_r.app` and choose `Open` if macOS blocks it.
5. If macOS later blocks a video by filename, open `System Settings` >
   `Privacy & Security`, choose `Open Anyway` for that trusted video, and
   authenticate when prompted. This can happen for a downloaded video that
   still has macOS quarantine information.

Only choose `Open Anyway` for videos obtained from a source you trust.

Windows:

1. Extract the zip.
2. Open the `mpv_r` folder.
3. Run `create-desktop-shortcut.cmd` and drag videos onto the new shortcut, or
   drag videos directly onto `mpv_r.exe`.
4. If Windows SmartScreen appears, continue only if the ZIP came from the
   project Release assets and its published SHA-256 matches.

Open Videos
-----------

- Drag one or more video files onto `mpv_r.app` or `mpv_r.exe`.
- Or open a video file from mpv_r.

Multiple files are loaded as a playlist.

Shortcuts
---------

Keyboard shortcuts are included in:

- `documents/shortcuts.md`

Japanese reference translation:

- `documents/translations_ja/shortcuts_jp.md`

Usage Guide
-----------

The author's original operation article is here:

https://note.com/kawakoshi_shi/n/n8a5734586eda

Project and releases:

https://github.com/kawakoshi/mpv_r

Notes
-----

- English documents are authoritative.
- Japanese files under `documents/translations_ja` are reference translations.
- License texts, notices, and source/build information are under `documents`.
- On Mac v0.3, these documents are bundled inside `mpv_r.app`.
- Do not download GitHub's automatic `Source code (zip)` if you want to run the
  app. Use the attached app package under GitHub Release assets.
