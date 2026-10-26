# MSYS2によるWindows x64向けmpvビルド 日本語参考訳

注意:
この文書は、公開前の確認を助けるために機械翻訳をもとに作成した日本語参考訳です。
翻訳の正確性、完全性、法的解釈について、本プロジェクトは一切の責任を負いません。
正式な内容は英語原文を優先してください。
また、世界中の翻訳者の知識、労力、文化をつなぐ仕事に深い敬意を表します。

## 目的

この手順では、プロジェクト管理下のWindows x64向けmpvランタイムをビルドし、必要なMINGW64 DLLをポータブルフォルダへ集めます。インストーラーの作成や実行ファイルへの署名は行いません。

Windows上のMSYS2 **MINGW64** シェルから実行します。Mesonビルドに通常のMSYSシェルやコマンドプロンプトを使わないでください。

## 初回確認済みビルド

クリーンなポータブルビルドを2026-10-26に確認しました。

- ソースタグとコミット: `v0.41.0` / `41f6a645068483470267271e1d09966ca3b9f413`
- 環境: MSYS2 MINGW64、GCC 16.1.0、Meson 1.11.1、Ninja 1.13.2
- 対象: Windows x64
- D3D11、Vulkan、WASAPI、libmpv、FFmpeg、libplacebo、libass、LuaJIT、JPEG、shaderc、zimgなどを有効化
- ポータブルランタイム: `mpv.exe`、`mpv.com`、DLL 114本の計116ファイル、約197 MB
- ポータブル検証: `/mingw64/bin`を含まないPATHで、`mpv.exe --no-config --no-audio --vo=null`によりローカルH.264テスト動画を最後までデコード

MSYS2パッケージの更新によりランタイムファイル数は変わります。DLLの手書きリストは保守せず、各ビルドで`ldd`から導出してください。

## 前提条件

- Windows x64
- MINGW64ツールチェーンとmpvが必要とする依存関係を含むMSYS2
- MINGW64シェルでGit、Meson、Ninja、`ldd`が利用可能であること
- 初回実行時に`https://github.com/mpv-player/mpv.git`をクローンできるネットワーク接続

MSYS2の依存関係はupstream mpvのCIワークフローを最新の参照として扱います。このプロジェクトのビルドでは、任意の開発コミットではなくリリース済みmpvタグへ固定してください。

## ビルドとランタイム収集

MSYS2 MINGW64シェルで`mpv_r`リポジトリから実行します。

```sh
MPV_TAG=v0.41.0 \
MPV_TEST_FILE=/c/path/to/approved-test.mp4 \
packaging/scripts/build-mpv-windows-msys2.sh
```

標準の保存先は以下です。

```text
/c/work/codex/repos/mpv-r-upstream-v0.41.0
/c/work/codex/builds/mpv_r-v0.41.0-portable
```

スクリプトは、未コミット変更があるソースチェックアウトの利用と、既存ポータブル出力フォルダの上書きを拒否します。これにより、以前のテストと今回の記録が混ざることを防ぎます。

出力フォルダには`mpv.exe`、`mpv.com`、`libmpv-2.dll`、`ldd`が`/mingw64`配下として報告したすべてのDLL、`FILELIST.txt`が入ります。`C:\Windows`配下のシステムDLLは意図的にコピーしません。

## 検証

スクリプトはまず、ポータブルフォルダと`C:\Windows\System32`だけを含むPATHで`mpv.exe --version`を実行します。`MPV_TEST_FILE`を指定した場合は、nullビデオ出力でファイルをデコードします。このランタイムで`mpv_r`をパッケージ化した後、別途Windowsスモークテストを実行してください。

## パッケージ入力

生成したランタイムフォルダをWindowsパッケージスクリプトへ渡します。

```sh
WINDOWS_MPV_DIR=/c/work/codex/builds/mpv_r-v0.41.0-portable \
packaging/scripts/build-windows.sh
```

パッケージスクリプトは、このフォルダから実行ファイルとDLLをコピーします。旧来の第三者mpvバイナリ構成は使いません。
