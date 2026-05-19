# mpv_r

注意:
この文書は、公開前の確認を助けるために機械翻訳をもとに作成した日本語参考訳です。
翻訳の正確性、完全性、法的解釈について、本プロジェクトは一切の責任を負いません。
正式な内容は英語原文を優先してください。
また、世界中の翻訳者の知識、労力、文化をつなぐ仕事に深い敬意を表します。

`mpv_r`は、mpvをベースにしたmacOS向けの映像チェック用プレイヤーです。

このv0.1.0は、作者が以前公開した`mpv_r`設定を、フレーム単位の確認、簡易再生チェック、複数ファイル確認、スクリーンショット保存に使いやすい形で再配布するMac Previewです。

Windows Previewはv0.1.1で予定しています。

## ダウンロード

GitHub Releasesからアプリ配布zipをダウンロードしてください。

- `mpv_r-mac-v0.1.0.zip`

アプリを使いたい場合は、GitHubが自動生成する`Source code (zip)`ではなく、Release assetsに添付されているzipを選んでください。

## macOSへのインストール

1. `mpv_r-mac-v0.1.0.zip`をダウンロードします。
2. zipを展開します。
3. `mpv_r.app`を`/Applications`へ移動します。
4. 初回起動時は、`mpv_r.app`を右クリックして`開く`を選びます。
5. macOSの警告が出た場合は、もう一度`開く`を選びます。

このPreviewはnotarizationを行っていないため、初回起動時に右クリックから開く必要がある場合があります。

## 動画を開く

- 1つまたは複数の動画ファイルを`mpv_r.app`へドラッグ&ドロップします。
- または、動画ファイルを右クリックし、`このアプリケーションで開く`から`mpv_r`を選びます。

複数ファイルはプレイリストとして読み込まれます。

## 基本操作

このPreviewでは、旧`mpv_r`の操作感を維持しています。

- `Space` / テンキー`0`: 再生 / 一時停止
- `Left` / `Right`: 1フレーム戻る / 進む
- `Up` / `Down`: 前のファイル / 次のファイル
- `Shift + Left` / `Shift + Right`: 1秒戻る / 進む
- `Shift + Up` / `Shift + Down`: 30秒戻る / 進む
- `/`: スクリーンショット
- `f` / `*`: フルスクリーン
- `Esc`: フルスクリーン解除
- `Command + W` / `Control + W`: 終了

スクリーンショットはデスクトップに保存されます。

## 同梱しているmpvビルド

このリリースは、mpv `0.39.0`を同梱しています。

macOS版mpvは、mpv公式インストールページで案内されているstolendataによる非公式third-party buildを使用しています。

- https://mpv.io/installation/
- https://laboratory.stolendata.net/~djinn/mpv_osx/

本プロジェクトはmpv-playerおよびstolendataとは無関係です。

ライセンスとクレジットの詳細は、`NOTICE.md`と`LICENSES/`を参照してください。

## 設定ファイル

同梱設定は以下にあります。

- `config/mac/mpv.conf`
- `config/mac/input.conf`

## ロードマップ

- v0.1.0: Mac Preview
- v0.1.1: Windows Preview
- v0.2: ドキュメント、ライセンス同梱、アイコン、リリース手順の整理
- v0.3: mpv自前ビルドの検証
- v1.0: 最初のStable/LTSリリース

