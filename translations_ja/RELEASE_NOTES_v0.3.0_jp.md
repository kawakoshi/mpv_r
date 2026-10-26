# mpv_r v0.3.0 - Mac Apple Silicon DMG Preview 日本語参考訳

注意:
この文書は、公開前の確認を助けるために機械翻訳をもとに作成した日本語参考訳です。
翻訳の正確性、完全性、法的解釈について、本プロジェクトは一切の責任を負いません。
正式な内容は英語原文を優先してください。
また、世界中の翻訳者の知識、労力、文化をつなぐ仕事に深い敬意を表します。

v0.3.0では、Mac PreviewパッケージをApple Silicon向けに自前ビルドしたmpvバンドルへ更新し、MacらしいDMG形式のインストール手順を導入します。

## ダウンロード

ダウンロード:

- `mpv_r-mac-v0.3.0.dmg`

アプリとして使う場合は、Release assetsに添付されたアプリ用パッケージを使ってください。GitHubが自動生成する`Source code (zip)`はアプリ本体ではありません。

## 変更内容

- Mac PreviewをDMG形式で配布します。
- Mac DMGには`mpv_r.app`と`Applications`へのショートカットを入れています。
- Mac版のドキュメント、NOTICE、ライセンス文書、日本語参考訳は`mpv_r.app`の中に同梱します。
- Mac Previewは、このプロジェクトでビルドしたApple Silicon向けmpv v0.41.0バンドルを使います。
- Macアプリには、v0.2作業中に追加したmpv_r仮アイコンを引き続き使います。
- Windows版は、別途公開済みのv0.2.0ポータブルzipパッケージを継続します。

## プラットフォームごとの注意

Mac:

- v0.3.0はApple Silicon Macを対象にしています。
- Intel Macはv0.3.0の対象外です。Intel Macでは、既存のmpvビルド、または以前のmpv_r Previewパッケージを使ってください。
- Macアプリはad-hoc署名済みですが、notarizationは行っていません。
- macOSにブロックされた場合、初回起動時は`mpv_r.app`を右クリックして`開く`を選んでください。

Windows:

- このMac専用リリースでは、Windows v0.3.0パッケージを公開しません。
- 現在公開されているWindowsパッケージはv0.2.0です。
- Windows向けの文書とパッケージ改善は、別途準備します。

## ドキュメント

プロジェクトのドキュメントは以下の2箇所にあります。

- GitHubリポジトリ内のドキュメント
- 同梱アプリパッケージ内のドキュメント

Mac版では、同梱ドキュメントは以下に入っています。

```text
mpv_r.app/Contents/Resources/documents/
```

これにより、ユーザーが見るDMGはシンプルにしつつ、README、NOTICE、ライセンス、ソース/ビルド情報、ショートカット、日本語参考訳をアプリバンドル内に保持します。

## 同梱内容

Mac DMG:

- `mpv_r.app`
- `Applications`ショートカット
- `mpv_r.app`内の`documents`
- `mpv_r.app`内の更新した`mpv_r`設定ファイル

## 注意

- これはプレビューリリースです。
- このプロジェクトはmpv-playerまたは同梱mpvビルド配布元とは関係ありません。

## チェックサム

SHA256:

```text
120e03b2abc960c27974fd725b647f8835cb3777725da34119f64d9d6067b80a  mpv_r-mac-v0.3.0.dmg
```
