# macOSパッケージングメモ 日本語参考訳

注意:
この文書は、公開前の確認を助けるために機械翻訳をもとに作成した日本語参考訳です。
翻訳の正確性、完全性、法的解釈について、本プロジェクトは一切の責任を負いません。
正式な内容は英語原文を優先してください。
また、世界中の翻訳者の知識、労力、文化をつなぐ仕事に深い敬意を表します。

v0.1.0は手動でパッケージングしました。

## 現在のv0.1.0の状態

公開済みのv0.1.0 Mac Previewは使用できますが、パッケージ構成はWindows
v0.1.1より古い状態です。

v0.2で整理する差分:

- 日本語参考訳ファイルがパッケージ直下に混在している。
- `source-and-build-info_jp.txt`がまだ`LICENSES`配下にある。
- Windows版の`translations_ja`方針とまだ揃っていない。
- パッケージング手順がまだ手動。

## v0.2の目標構成

v0.2では、MacパッケージもWindows版と同じ方針に揃えます。

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

英語ファイルを正式な文書とし、日本語ファイルは参考訳として
`translations_ja`配下にまとめます。

## 手動フロー

1. `mpv_r.app`を用意する。
2. README、NOTICE、LICENSE、LICENSESを同梱する。
3. 日本語参考訳を`translations_ja`配下に追加する。
4. `mpv_r-mac-v0.2.0.zip`を作る。
5. macOS用の簡易テストチェックリストを実行する。
6. GitHub Releasesへzipをアップロードする。

## macOSリリースノートのチェック項目

リリースノートには以下を含めます。

- 対象のmacOSパッケージ名
- 変更内容の短い説明
- 同梱内容
- ad-hoc署名とnotarizationの状態
- 初回起動時のGatekeeper注意
- 同梱mpvのバージョンとビルド元
- プロジェクトがmpv-playerやビルド配布元と無関係であること
- 簡易テスト結果
- SHA256チェックサム

手動フローを確認したあと、自動化を検討します。
