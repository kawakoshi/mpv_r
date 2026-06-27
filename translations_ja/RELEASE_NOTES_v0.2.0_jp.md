# mpv_r v0.2.0 - Package Cleanup 日本語参考訳

注意:
この文書は、公開前の確認を助けるために機械翻訳をもとに作成した日本語参考訳です。
翻訳の正確性、完全性、法的解釈について、本プロジェクトは一切の責任を負いません。
正式な内容は英語原文を優先してください。
また、世界中の翻訳者の知識、労力、文化をつなぐ仕事に深い敬意を表します。

v0.2.0では、Mac版とWindows版のパッケージ構成を揃え、両OSで同じ
ドキュメント方針と翻訳配置にします。

## ダウンロード

ダウンロード:

- `mpv_r-mac-v0.2.0.zip`
- `mpv_r-windows-v0.2.0.zip`

アプリとして使う場合は、Release assetsに添付されたzipを使ってください。
GitHubが自動生成する`Source code (zip)`はアプリ本体ではありません。

## 変更内容

- Mac版とWindows版のパッケージ構成を揃える。
- 両OSで、起動アプリ、`resources`、`documents`という同じ第一階層にする。
- 日本語参考訳を`documents/translations_ja`配下にまとめる。
- 英語のREADME、NOTICE、LICENSE、LICENSESは`documents`配下に置く。
- リリース確認用の簡易テストチェックリストを追加する。
- 明記しない限り、アプリの挙動はv0.1.xと互換にする。

## 同梱内容

Macパッケージ:

- `mpv_r.app`
- 更新した`mpv_r`設定ファイルを含む`resources/config`
- README、インストールメモ、日本語参考訳、mpvのライセンス文書、
  ソース/ビルド情報リンクを含む`documents`

Windowsパッケージ:

- `mpv_r.exe`
- 同梱された`resources/mpv/mpv.exe`
- 更新した`mpv_r`設定ファイルを含む`resources/config`
- README、インストールメモ、日本語参考訳、mpvのライセンス文書、
  ソース/ビルド情報リンクを含む`documents`

Windowsパッケージには、上流mpvの`doc/manual.pdf`や`doc/mpbindings.png`は
同梱しません。mpvのドキュメントはNOTICEやソース情報からリンクします。

## 注意

- これはプレビューリリースです。
- Macアプリはad-hoc署名済みですが、notarizationは行っていません。
- Macで初回起動する場合は、アプリを右クリックして`開く`を選んでください。
- Windowsランチャーはコード署名されていません。Windows SmartScreenの挙動は環境によって異なる場合があります。
- このプロジェクトはmpv-playerまたは同梱mpvビルド配布元とは関係ありません。

## 簡易テスト

公開前に、各プラットフォームの簡易テストチェックリストを実行します。

- `docs/smoke-test-mac.md`
- Windowsチェックリスト: 今後追加

## チェックサム

SHA256:

```text
dcc5a9498eff9d2e68e976e0c79f9160db4688fe680361c5b308b298d519232e  mpv_r-mac-v0.2.0.zip
77c5d19a533cf5d23a88e0c076d1eec10ec0d425337cb165b69590ad6f369eba  mpv_r-windows-v0.2.0.zip
```
