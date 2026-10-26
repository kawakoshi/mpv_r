# NOTICE 日本語参考訳

注意:
この文書は、公開前の確認を助けるために機械翻訳をもとに作成した日本語参考訳です。
翻訳の正確性、完全性、法的解釈について、本プロジェクトは一切の責任を負いません。
正式な内容は英語原文を優先してください。
また、世界中の翻訳者の知識、労力、文化をつなぐ仕事に深い敬意を表します。

特にライセンス文書については、この日本語訳ではなく、同梱された英語原文を必ず参照してください。

`mpv_r`は、mpvをベースにした動画レビュー用プレイヤー配布版です。

## mpv

mpv公式サイト:

- https://mpv.io/

mpvソースコード:

- https://github.com/mpv-player/mpv

mpvマニュアル:

- https://mpv.io/manual/

mpvのライセンス情報:

- `LICENSES/mpv-Copyright.txt`
- `LICENSES/mpv-LICENSE.GPL.txt`
- `LICENSES/mpv-LICENSE.LGPL.txt`

mpvは通常GPLv2 or laterとして配布されています。GPLを無効にしてビルドされた場合は
LGPLv2.1 or laterとして扱われることがあります。このプロジェクトでは、後のビルドで
明記しない限り、同梱mpvビルドをGPL系ソフトウェアとして扱います。

## 同梱mpvビルド

Macパッケージには、mpvインストールページからリンクされている、
stolendataによる非公式の第三者macOS版mpvビルドを同梱します。

ビルド配布元:

- https://laboratory.stolendata.net/~djinn/mpv_osx/

公開済みのWindows v0.2.0パッケージには、shinchiroによる非公式の第三者Windows版mpvビルドを同梱しています。Windows v0.3.0候補はMSYS2 MINGW64上でこのプロジェクトがビルドしたmpv v0.41.0を使いますが、ランタイムDLLのNOTICEと対応ソースを準備中のため、まだ公開しません。

ビルド配布元:

- https://github.com/shinchiro/mpv-winbuild-cmake

これらの同梱mpvビルドはmpv-player公式ビルドではありません。このプロジェクトはmpv-player、stolendata、shinchiro、MSYS2とは関係なく、この配布はそれらのプロジェクトから承認されたものではありません。

## mpv_r設定

`mpv_r`の設定ファイルとドキュメントは、元の`mpv_r` note記事の作者によって
管理されています。

同梱設定:

- `config/mac/mpv.conf`
- `config/mac/input.conf`
- `config/windows/mpv.conf`
- `config/windows/input.conf`

これらのファイルは、このPreviewで使用する、確認作業向けの再生挙動、
キーボード操作、起動時一時停止、プレイリストループ、スクリーンショット設定を
提供します。

## パッケージ生成

パッケージは以下で生成します。

- `packaging/scripts/build-mac.sh`
- `packaging/scripts/build-windows.sh`
- `packaging/scripts/build-all.sh`

Mac v0.3.0はApple Silicon向けに自前ビルドしたmpvアプリバンドルからDMGを作成します。Windows v0.2.0は第三者ビルドを使った公開版です。Windows v0.3.0候補は自前ビルドのランタイムを使いますが、`docs/windows-selfbuild-license-audit.md`の公開前要件を満たすまで配布しません。

## 今後の方向性

v0.xでは、動作するユーザー体験を優先します。将来のリリースでは、mpvを自前で
ビルドし、ビルド手順をこのプロジェクト内で直接再現・文書化できるよう検討します。
