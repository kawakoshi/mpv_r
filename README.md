# mpv_r

> このREADMEは、作成者と主な利用者が日本語話者のため日本語から始めます。英語版はこのページの後半にあります。ライセンス、NOTICE、ソース／ビルド情報は、配布物に入る英語原文を正本とします。

`mpv_r`は、動画をフレーム単位で確認し、連続する複数ファイルを見比べ、スクリーンショットを残すためのMac／Windows向け動画レビュー用プレイヤーです。mpvにレビュー向けの設定を組み合わせています。

## ダウンロード

アプリとして使うときは、GitHubが自動生成する`Source code (zip)`ではなく、Releasesの**Assets**にある配布ファイルを使ってください。

- Mac：`mpv_r-mac-v0.3.0.dmg`（公開中）
- Windows：`mpv_r-windows-v0.2.0.zip`（公開中）

Windowsの自前ビルド版v0.3.0は、DLL・ライセンス・対応ソースの監査と最終ZIP検証を完了し、公開準備中です。公開後はWindowsも`mpv_r-windows-v0.3.0.zip`へ揃えます。

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
- Windows v0.2.0：shinchiroによる第三者ビルドを同梱した、従来の公開版です。
- Windows v0.3.0：MSYS2上でこのプロジェクトがビルドしたmpv v0.41.0を使います。DLL・ライセンス・対応ソースの監査と最終ZIP検証は完了し、Release assetと対応ソースの公開準備中です。

mpv-player、stolendata、shinchiroとの関係やライセンス情報は[NOTICE.md](NOTICE.md)と[LICENSES/](LICENSES/)を参照してください。

## 開発・パッケージング

- Macビルド：[docs/build-mpv-macos-arm64.md](docs/build-mpv-macos-arm64.md)
- Windows自前ビルド：[docs/build-mpv-windows-msys2.md](docs/build-mpv-windows-msys2.md)
- Windows公開前のライセンス確認：[translations_ja/windows-selfbuild-license-audit_jp.md](translations_ja/windows-selfbuild-license-audit_jp.md)（[English](docs/windows-selfbuild-license-audit.md)）

設定ファイルは`config/mac/`と`config/windows/`にあります。

## ロードマップ

- v0.3.0：Mac Apple Silicon DMG／Windows 64-bitポータブルZIP
- 次：Windows v0.3.0と対応ソースの公開
- その次：Windowsインストーラーと、Mac／Windows v0.4.0の整備

---

# mpv_r — English

> This README starts in Japanese because its author and primary users are Japanese speakers. Licensing, notice, source, and build documents shipped with the app remain authoritative in English.

`mpv_r` is a video review player for macOS and Windows. It packages mpv with review-oriented settings for frame-by-frame checking, comparing adjacent files, and taking screenshots.

## Downloads

Use an app package under GitHub Releases **Assets**, not GitHub's automatic `Source code (zip)` archive.

- macOS: `mpv_r-mac-v0.3.0.dmg` (published)
- Windows: `mpv_r-windows-v0.2.0.zip` (published)

The project-built Windows v0.3.0 runtime has completed its DLL, license,
corresponding-source, and final-ZIP audits. Its release assets are being
prepared; after publication, Windows will use `mpv_r-windows-v0.3.0.zip`.

## Usage

- macOS: Drag one or more videos onto `mpv_r.app`, or open a video from the app.
- Windows: Keep the extracted `mpv_r` folder together and drag video files onto the Desktop shortcut created by the supplied command, or directly onto `mpv_r.exe`.

Multiple files open as a playlist. See [docs/shortcuts.md](docs/shortcuts.md) for keyboard controls and [docs/windows-preview-guide.md](docs/windows-preview-guide.md) for the Windows package guide.

## Build and Release Status

- macOS v0.3.0 bundles a project-built Apple Silicon mpv v0.41.0 app bundle.
- The published Windows v0.2.0 package uses a third-party mpv build by shinchiro.
- Windows v0.3.0 uses a project-built MSYS2 runtime. Its license and package audits are complete; the ZIP and corresponding-source release assets are being prepared.

See [NOTICE.md](NOTICE.md), [LICENSES/](LICENSES/), [docs/build-mpv-windows-msys2.md](docs/build-mpv-windows-msys2.md), and [docs/windows-selfbuild-license-audit.md](docs/windows-selfbuild-license-audit.md).
