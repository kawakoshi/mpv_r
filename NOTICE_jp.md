# NOTICE 日本語参考訳

注意:
この文書は、公開前の確認を助けるために機械翻訳をもとに作成した日本語参考訳です。
翻訳の正確性、完全性、法的解釈について、本プロジェクトは一切の責任を負いません。
正式な内容は英語原文を優先してください。
また、世界中の翻訳者の知識、労力、文化をつなぐ仕事に深い敬意を表します。

特にライセンス文書については、この日本語訳ではなく、同梱された英語原文を必ず参照してください。

`mpv_r`は、mpvをベースにした映像チェック用プレイヤー配布物です。

## mpv

このリリースはmpv `0.39.0`を同梱しています。

mpv公式サイト:

- https://mpv.io/

mpvソースコード:

- https://github.com/mpv-player/mpv

mpvのライセンス情報:

- `LICENSES/mpv-Copyright.txt`
- `LICENSES/mpv-LICENSE.GPL.txt`
- `LICENSES/mpv-LICENSE.LGPL.txt`

mpvは通常GPLv2 or laterとして配布されています。GPLを無効にしてビルドされた場合はLGPLv2.1 or laterとして扱われることがあります。このv0.1.0配布物では、同梱mpvアプリをGPL系ソフトウェアとして扱い、対応するライセンス本文とソースコードへのリンクを同梱しています。

## macOSビルドの出所

このv0.1.0 Mac Previewは、mpv公式インストールページで案内されているstolendataによるmacOS向け非公式third-party buildを同梱しています。

ビルド配布元:

- https://laboratory.stolendata.net/~djinn/mpv_osx/

ダウンロードしたアーカイブ:

- `mpv-latest.tar.gz`

同梱mpvバージョン:

- `0.39.0`

stolendataによるビルドは、mpv-player公式ビルドではありません。本プロジェクトはmpv-playerおよびstolendataとは無関係であり、この配布物はどちらのプロジェクトからも承認・配布されているものではありません。

## mpv_r設定

`mpv_r`の設定ファイルとドキュメントは、元の`mpv_r` note記事の作者によって管理されています。

同梱設定:

- `config/mac/mpv.conf`
- `config/mac/input.conf`

これらのファイルは、このPreviewで使用する、確認作業向けの再生挙動、キーボード操作、起動時一時停止、プレイリストループ、スクリーンショット設定を提供します。

## 今後の方向性

v0.1.xでは、動作するユーザー体験を優先します。将来のリリースでは、mpvを自前でビルドし、ビルド手順をこのプロジェクト内で直接再現・文書化できるよう検討します。

