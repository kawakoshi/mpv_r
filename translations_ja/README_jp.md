# mpv_r 日本語参考訳

注意:
この文書は、公開前の確認を助けるために機械翻訳をもとに作成した日本語参考訳です。
翻訳の正確性、完全性、法的解釈について、本プロジェクトは一切の責任を負いません。
正式な内容は英語原文を優先してください。
また、世界中の翻訳者の知識、労力、文化をつなぐ仕事に深い敬意を表します。

`mpv_r`は、MacとWindows向けの動画レビュー用プレイヤーです。

mpvに作者のレビュー向け設定を組み合わせ、動画をフレーム単位で確認したり、
前後のファイルを見比べたり、スクリーンショットを残したりできるようにした
配布版です。

日本語参考訳は`translations_ja/`にあります。

英語ファイルが正式な内容です。日本語ファイルは確認と理解を助けるための参考訳です。

## ダウンロード

GitHub Releasesからアプリ配布zipをダウンロードしてください。

- `mpv_r-mac-v0.2.0.zip`
- `mpv_r-windows-v0.2.0.zip`

アプリを使いたい場合は、GitHubが自動生成する`Source code (zip)`ではなく、
Release assetsに添付されているzipを選んでください。

## パッケージ構成

v0.2パッケージは、Mac版とWindows版で同じ第一階層の形にします。

```text
mpv_r/
  mpv_r.app または mpv_r.exe
  resources/
  documents/
```

`resources`には、同梱ランタイムファイルとmpv_r設定が含まれます。

`documents`には、README、NOTICE、ライセンス文書、ソース/ビルド情報、
キーボードショートカット、日本語参考訳が含まれます。

## 動画を開く

- 1つまたは複数の動画ファイルを`mpv_r.app`または`mpv_r.exe`へドラッグ&ドロップします。
- またはmpv_rから動画ファイルを開きます。

複数ファイルはプレイリストとして読み込まれます。

## ショートカット

キーボードショートカットは以下に記載しています。

- `docs/shortcuts.md`
- `translations_ja/shortcuts_jp.md`

元の操作記事はこちらです。

- https://note.com/kawakoshi_shi/n/n8a5734586eda

## 同梱mpvビルド

Macパッケージには、stolendataによる非公式の第三者macOS版mpvビルドを同梱します。

Windowsパッケージには、shinchiroによる非公式の第三者Windows版mpvビルドを
同梱します。

このプロジェクトはmpv-player、stolendata、shinchiroとは関係ありません。

ライセンス、クレジット、ソース/ビルド情報の詳細は`NOTICE.md`と`LICENSES/`を
参照してください。

## 設定ファイル

同梱設定は以下にあります。

- `config/mac/mpv.conf`
- `config/mac/input.conf`
- `config/windows/mpv.conf`
- `config/windows/input.conf`

## パッケージング

v0.2パッケージは以下で生成します。

- `packaging/scripts/build-mac.sh`
- `packaging/scripts/build-windows.sh`
- `packaging/scripts/build-all.sh`

これらのスクリプトは、既存のmpvビルド、mpv_r設定ファイル、プロジェクト文書を
集めてリリースzipを作成します。mpv本体をソースからビルドするものではありません。

## ロードマップ

- v0.1.0: Mac Preview
- v0.1.1: Windows Preview
- v0.2.0: Mac/Windowsパッケージ構成の整理
- v0.3: mpv自前ビルドの検証
- v1.0: 最初のStable/LTSリリース
