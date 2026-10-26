# Windowsパッケージングメモ 日本語参考訳

注意:
この文書は、公開前の確認を助けるために機械翻訳をもとに作成した日本語参考訳です。
翻訳の正確性、完全性、法的解釈について、本プロジェクトは一切の責任を負いません。
正式な内容は英語原文を優先してください。
また、世界中の翻訳者の知識、労力、文化をつなぐ仕事に深い敬意を表します。

現在のWindows版はv0.2.0です。小さなGo製ランチャーとポータブルZIPパッケージを使います。インストーラーではありません。

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

次のプロジェクトでビルドするmpvランタイムでは、まず以下を実行します。

```sh
MPV_TAG=v0.41.0 packaging/scripts/build-mpv-windows-msys2.sh
```

その後、`build-windows.sh`を実行するときにポータブル出力を`WINDOWS_MPV_DIR`へ渡します。パッケージスクリプトは固定の第三者mpvファイル一覧に依存せず、そのランタイムフォルダ内のすべての`.exe`と`.dll`をコピーします。

## ユーザー向け文書

現在のWindows向けガイドは以下です。

- `docs/windows-preview-guide.md`

展開、通常の起動、SmartScreen、ポータブルパッケージ一式を保つこと、レビュー操作、スクリーンショット、設定の復元を説明しています。

## v0.2の目標構成

```text
mpv_r/
  mpv_r.exe
  resources/
    mpv/
      mpv.exe
      mpv.com
      libmpv-2.dll
      *.dll（`ldd`から導出したランタイム依存関係）
      mpv/
        fonts.conf（ランタイム入力に含まれる場合のみ）
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
mpvのドキュメントはNOTICEやソース情報からリンクします。
