# mpv_r v0.3.0 - Mac／Windows自前ビルドPreview 日本語参考訳

注意:
この文書は、公開前の確認を助けるために機械翻訳をもとに作成した日本語参考訳です。
翻訳の正確性、完全性、法的解釈について、本プロジェクトは一切の責任を負いません。
正式な内容は英語原文を優先してください。
また、世界中の翻訳者の知識、労力、文化をつなぐ仕事に深い敬意を表します。

v0.3.0では、Apple Silicon Macと64-bit Windowsの両方で、自前ビルドしたmpv v0.41.0ランタイムを使います。MacはDMG、WindowsはポータブルZIPです。

## ダウンロード

ダウンロード:

- `mpv_r-mac-v0.3.0.dmg`
- `mpv_r-windows-v0.3.0.zip`
- `mpv_r-windows-v0.3.0-corresponding-source.tar.zst`

アプリとして使う場合は、Release assetsに添付されたアプリ用パッケージを使ってください。GitHubが自動生成する`Source code (zip)`はアプリ本体ではありません。

## 変更内容

- Mac PreviewをDMG形式で配布します。
- Mac DMGには`mpv_r.app`と`Applications`へのショートカットを入れています。
- Mac版のドキュメント、NOTICE、ライセンス文書、日本語参考訳は`mpv_r.app`の中に同梱します。
- Mac Previewは、このプロジェクトでビルドしたApple Silicon向けmpv v0.41.0バンドルを使います。
- Macアプリには、v0.2作業中に追加したmpv_r仮アイコンを引き続き使います。
- Windows版は、このプロジェクトでビルドしたMSYS2 MINGW64版mpv v0.41.0ランタイムへ更新します。
- Windows ZIPには、デスクトップショートカット作成cmdと、現在のユーザー向け関連付け登録cmdを収録します。
- Windows ZIPには、ランタイム・ソース・ライセンスの一覧と163件のライセンス文書を収録します。
- Windows版に使用した86件のMSYS2ソース、mpvソース、パッチ、ビルド記録は、対応ソースassetとして別に公開します。

## プラットフォームごとの注意

Mac:

- v0.3.0はApple Silicon Macを対象にしています。
- Intel Macはv0.3.0の対象外です。Intel Macでは、既存のmpvビルド、または以前のmpv_r Previewパッケージを使ってください。
- Macアプリはad-hoc署名済みですが、notarizationは行っていません。
- macOSにブロックされた場合、初回起動時は`mpv_r.app`を右クリックして`開く`を選んでください。
- その後、macOSが信頼できるダウンロード動画をファイル名でブロックした場合は、
  `システム設定` > `プライバシーとセキュリティ` > `このまま開く`で、その動画だけを許可し、
  求められた場合は認証してください。

Windows:

- v0.3.0はWindows 64-bitを対象にします。
- ポータブルZIPを一式のまま展開して使います。インストーラーではありません。
- 同梱cmdでデスクトップショートカットを作り、動画をそこへドラッグ&ドロップする使い方を推奨します。
- ランチャーと同梱mpvにはコード署名がないため、SmartScreenまたはSmart App Controlが警告・ブロックする場合があります。
- このプロジェクトのRelease assetsから取得し、公開SHA-256と一致するファイルだけを使用してください。

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

Windows ZIP:

- `mpv_r.exe`ランチャー
- 自前ビルドしたmpv v0.41.0ランタイムとDLL
- デスクトップショートカット作成cmdと関連付け登録cmd
- 英語文書と日本語参考訳
- ランタイム、ソース、ライセンス、最終パッケージの検証記録

## 注意

- これはプレビューリリースです。
- このプロジェクトはmpv-playerまたは同梱mpvビルド配布元とは関係ありません。

## チェックサム

SHA256:

```text
ea459df3693d9ca7791452c6adcec904c6832022520a68dec4e0b818b6cc10c8  mpv_r-mac-v0.3.0.dmg
23c75c83d05e4b52707b0fda2962b6b9189b755a9917004a31ceb2d01b9845a0  mpv_r-windows-v0.3.0.zip
ea4c4df1c3f62e9401b96cb22ef4208de64e13ed3f428d3a588d3961c85c8010  mpv_r-windows-v0.3.0-corresponding-source.tar.zst
```
