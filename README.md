# mpv_r

`mpv_r`は、動画をフレーム単位で確認し、連続する複数ファイルを見比べ、スクリーンショットを残すためのMac／Windows向け動画レビュー用プレイヤーです。mpvにレビュー向けの設定を組み合わせています。

English: [README_en.md](README_en.md)

## ダウンロード

アプリとして使うときは、GitHubが自動生成する`Source code (zip)`ではなく、Releasesの**Assets**にある配布ファイルを使ってください。

- Mac：`mpv_r-mac-v0.3.0.dmg`（公開中）
- Windows：`mpv_r-windows-v0.2.0.zip`（公開中）

Windowsの自前ビルド版v0.3.0は、DLLごとのライセンスと対応ソースを整理・確認中です。確認が終わるまで公開しません。

## 使い方

- Mac：`mpv_r.app`へ動画をドラッグ&ドロップするか、アプリから動画を開きます。
- Windows：展開した`mpv_r`フォルダをそのまま保ち、`mpv_r.exe`へ動画をドラッグ&ドロップします。次のポータブル版ではデスクトップショートカットを作り、そのショートカットへのドラッグ&ドロップを基本の使い方にします。

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
- Windows v0.3.0候補：MSYS2上でこのプロジェクトがビルドしたmpv v0.41.0を使います。ただしライセンス監査と対応ソースの公開準備が終わるまで、Releaseには追加しません。

mpv-player、stolendata、shinchiroとの関係やライセンス情報は[NOTICE.md](NOTICE.md)と[LICENSES/](LICENSES/)を参照してください。

## 開発・パッケージング

- Macビルド：[docs/build-mpv-macos-arm64.md](docs/build-mpv-macos-arm64.md)
- Windows自前ビルド：[docs/build-mpv-windows-msys2.md](docs/build-mpv-windows-msys2.md)
- Windows公開前のライセンス確認：[translations_ja/windows-selfbuild-license-audit_jp.md](translations_ja/windows-selfbuild-license-audit_jp.md)（[English](docs/windows-selfbuild-license-audit.md)）

設定ファイルは`config/mac/`と`config/windows/`にあります。

## ロードマップ

- v0.3.0：Mac Apple Silicon DMG Preview（公開中）
- 次のWindows版：自前ビルド版のライセンス対応とポータブル配布の整備
- その次：Windowsインストーラーと、明示的な関連付け登録の導入
