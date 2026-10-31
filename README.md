# mpv_r

> このREADMEは、作成者と主な利用者が日本語話者のため日本語から始めます。英語版はこのページの後半にあります。ライセンス、NOTICE、ソース／ビルド情報は、配布物に入る英語原文を正本とします。

`mpv_r`は、動画をフレーム単位で確認し、連続する複数ファイルを見比べ、スクリーンショットを残すためのMac／Windows向け動画レビュー用プレイヤーです。mpvにレビュー向けの設定を組み合わせています。

## ダウンロード

アプリとして使うときは、GitHubが自動生成する`Source code (zip)`ではなく、Releasesの**Assets**にある配布ファイルを使ってください。

- Mac：`mpv_r-mac-v0.3.0.dmg`（公開中）
- Windows：`mpv_r-windows-v0.3.0.zip`（公開中）

Windows v0.3.0の対応ソースは、同じReleaseの`mpv_r-windows-v0.3.0-corresponding-source.tar.zst`で公開しています。ハッシュは`SHA256SUMS_v0.3.0.txt`で確認できます。

## 使い方

- Mac：`mpv_r.app`へ動画をドラッグ&ドロップするか、アプリから動画を開きます。
- Windows：展開した`mpv_r`フォルダをそのまま保ち、同梱cmdで作成したデスクトップショートカットへ動画をドラッグ&ドロップします。`mpv_r.exe`へ直接ドラッグ&ドロップしても開けます。

複数ファイルを渡すと、プレイリストとして読み込みます。

主なキー操作は[docs/shortcuts.md](docs/shortcuts.md)にあります。日本語版は[translations_ja/shortcuts_jp.md](translations_ja/shortcuts_jp.md)です。

## 配布形態

Mac v0.3.0はApple Silicon向けのDMGです。文書はアプリ内の`mpv_r.app/Contents/Resources/documents/`に入っています。アプリはad-hoc署名でnotarizeはしていません。初回起動時にmacOSが止めた場合は、アプリを右クリックして「開く」を選んでください。

Windowsはインストーラーではない64-bitポータブルZIPです。

```text
mpv_r/
  mpv_r.exe
  resources/
  documents/
```

`resources`に同梱ランタイムと設定、`documents`にREADME、NOTICE、ライセンス、ソース／ビルド情報、ショートカット一覧を置きます。使い方とSmartScreenの注意は[docs/windows-preview-guide.md](docs/windows-preview-guide.md)を参照してください。

## 同梱するmpvと公開状況

- Mac v0.3.0：このプロジェクトでビルドしたApple Silicon向けmpv v0.41.0を同梱しています。
- Windows v0.2.0：shinchiroによる第三者ビルドを同梱した、以前の公開版です。
- Windows v0.3.0：MSYS2上でこのプロジェクトがビルドしたmpv v0.41.0を使います。DLL・ライセンス・対応ソースの監査、最終ZIP検証、実機操作確認を完了して公開しています。

mpv-player、stolendata、shinchiroとの関係やライセンス情報は[NOTICE.md](NOTICE.md)と[LICENSES/](LICENSES/)を参照してください。

## 開発・パッケージング

- Macビルド：[docs/build-mpv-macos-arm64.md](docs/build-mpv-macos-arm64.md)
- Windows自前ビルド：[docs/build-mpv-windows-msys2.md](docs/build-mpv-windows-msys2.md)
- Windows公開前のライセンス確認：[translations_ja/windows-selfbuild-license-audit_jp.md](translations_ja/windows-selfbuild-license-audit_jp.md)（[English](docs/windows-selfbuild-license-audit.md)）

設定ファイルは`config/mac/`と`config/windows/`にあります。

## ロードマップ

- v0.3.0：Mac Apple Silicon DMG／Windows 64-bitポータブルZIP
- 次：Windowsインストーラーと、Mac／Windows v0.4.0の整備
- v0.4.0メモ：Windowsの再生ウィンドウは同梱`mpv.exe`側のアイコンを表示するため、ショートカット／関連付け／再生ウィンドウのアイコン統一を検討します。mpvバイナリへ変更を加える場合は、ランタイム監査とハッシュ検証をやり直します。

---

# mpv_r — English

> This README starts in Japanese because its author and primary users are Japanese speakers. Licensing, notice, source, and build documents shipped with the app remain authoritative in English.

`mpv_r` is a video review player for macOS and Windows. It packages mpv with review-oriented settings for frame-by-frame checking, comparing adjacent files, and taking screenshots.

## Downloads

Use an app package under GitHub Releases **Assets**, not GitHub's automatic `Source code (zip)` archive.

- macOS: `mpv_r-mac-v0.3.0.dmg` (published)
- Windows: `mpv_r-windows-v0.3.0.zip` (published)

The matching Windows source is published in the same release as
`mpv_r-windows-v0.3.0-corresponding-source.tar.zst`. Verify the assets with
`SHA256SUMS_v0.3.0.txt`.

## Usage

- macOS: Drag one or more videos onto `mpv_r.app`, or open a video from the app.
- Windows: Keep the extracted `mpv_r` folder together and drag video files onto the Desktop shortcut created by the supplied command, or directly onto `mpv_r.exe`.

Multiple files open as a playlist. See [docs/shortcuts.md](docs/shortcuts.md) for keyboard controls and [docs/windows-preview-guide.md](docs/windows-preview-guide.md) for the Windows package guide.

## Build and Release Status

- macOS v0.3.0 bundles a project-built Apple Silicon mpv v0.41.0 app bundle.
- The earlier Windows v0.2.0 package uses a third-party mpv build by shinchiro.
- Windows v0.3.0 publishes a project-built MSYS2 runtime after completing its license, package, corresponding-source, and manual smoke-test checks.

For v0.4.0, investigate using one mpv_r icon consistently for the Windows
shortcut, file associations, and playback window. The playback window currently
uses the icon from the bundled `mpv.exe`; any binary resource change requires
rerunning the runtime audit and hash verification.

See [NOTICE.md](NOTICE.md), [LICENSES/](LICENSES/), [docs/build-mpv-windows-msys2.md](docs/build-mpv-windows-msys2.md), and [docs/windows-selfbuild-license-audit.md](docs/windows-selfbuild-license-audit.md).
