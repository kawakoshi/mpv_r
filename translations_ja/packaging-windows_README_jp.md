# Windowsパッケージングメモ 日本語参考訳

注意:
この文書は、公開前の確認を助けるために機械翻訳をもとに作成した日本語参考訳です。
翻訳の正確性、完全性、法的解釈について、本プロジェクトは一切の責任を負いません。
正式な内容は英語原文を優先してください。
また、世界中の翻訳者の知識、労力、文化をつなぐ仕事に深い敬意を表します。

v0.1.1では、小さなGo製ランチャーを使います。v0.2でもこの方針を維持し、
Mac版とWindows版が同じソフトの配布物に見えるようにパッケージ構成を変更します。

- ソース: `cmd/mpv-r-launcher/main.go`
- 出力: `mpv_r.exe`

このランチャーは、同梱された`resources/mpv/mpv.exe`を以下の指定付きで起動します。

```text
--config-dir=resources/config
```

ドラッグ&ドロップされたファイル引数は、そのままmpvへ渡します。

## ビルド

```sh
packaging/scripts/build-windows.sh
```

`-H windowsgui`は、Explorerからランチャーを起動したときにコンソールウィンドウを出さないための指定です。

## v0.2の目標構成

```text
mpv_r/
  mpv_r.exe
  resources/
    mpv/
      mpv.exe
      mpv.com
      d3dcompiler_43.dll
      mpv/
        fonts.conf
    config/
      mpv.conf
      input.conf
  documents/
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

上流mpvに含まれる`doc/manual.pdf`と`doc/mpbindings.png`は、v0.2では同梱しません。
mpvのドキュメントはNOTICEやソース情報からリンクし、mpv_rの使い方はこの
プロジェクトとnote記事で案内します。
