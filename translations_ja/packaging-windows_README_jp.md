# Windowsパッケージングメモ 日本語参考訳

注意:
この文書は、公開前の確認を助けるために機械翻訳をもとに作成した日本語参考訳です。
翻訳の正確性、完全性、法的解釈について、本プロジェクトは一切の責任を負いません。
正式な内容は英語原文を優先してください。
また、世界中の翻訳者の知識、労力、文化をつなぐ仕事に深い敬意を表します。

v0.1.1では、小さなGo製ランチャーを使います。

- ソース: `cmd/mpv-r-launcher/main.go`
- 出力: `mpv_r.exe`

このランチャーは、同梱された`mpv/mpv.exe`を以下の指定付きで起動します。

```text
--config-dir=portable_config
```

ドラッグ&ドロップされたファイル引数は、そのままmpvへ渡します。

## ビルド

```sh
GOCACHE="$PWD/build/go-cache" GOOS=windows GOARCH=amd64 go build -ldflags "-H windowsgui" -o build/windows/mpv_r.exe ./cmd/mpv-r-launcher
```

`-H windowsgui`は、Explorerからランチャーを起動したときにコンソールウィンドウを出さないための指定です。
