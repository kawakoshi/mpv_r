# macOS arm64向けmpvビルドメモ

> 注意: この日本語文書は、英語版 `docs/build-mpv-macos-arm64.md` の内容理解を助けるための参考訳です。機械翻訳を含むため、翻訳の正確性や解釈について一切の責任を負いません。正式な内容は英語版を確認してください。世界中の翻訳者と、言葉を越えて知識を届ける仕事に、尊敬と敬意を表します。

これは、mpv_rのApple Silicon向け自前ビルド検証メモです。

最初に成功したテストでは、Apple Silicon Mac上でmpv `v0.41.0` をビルドし、ローカルの `mpv_r` 試用ビルドとしてパッケージ化しました。

## 状態

- mpv `v0.41.0` はmacOS arm64向けにビルドできました。
- 生成された `mpv.app` はApple Silicon上で起動し、動画を再生できました。
- 生成されたapp bundleは `mpv_r.app` として再パッケージ化できました。
- 再パッケージ化した `mpv_r.app` は、ローカル検証では以前のMac Preview版より起動が速くなりました。
- ローカル検証では、mpv_rの基本操作が動作しました。
  - 再生
  - コマ送り
  - プレイリスト内のファイル移動
  - スクリーンショット撮影

これはまだ試用ビルドです。標準のMacリリースビルドにする前に、日常使用での検証が必要です。

## ビルド場所

最初の検証で使ったローカルのソースチェックアウトは、リリース用リポジトリの外に置きました。

```sh
/Users/mba2026/Documents/codex_hisyo/開発/アプリ/VideoReviewPlayer/build-src/mpv
```

これにより、upstream mpvのソースとビルド出力を、mpv_rのリリース用リポジトリから分離できます。

## ツール

最初に成功したビルドでは、以下を使用しました。

- Apple Command Line Tools
- arm64ターゲットのclang
- Homebrew
- Meson
- Ninja
- pkgconf
- Apple Command Line Tools由来のSwift toolchain

MesonとNinjaはHomebrewでインストールしました。

```sh
brew install meson ninja
```

最初に成功したconfigureでは、Homebrewが提供する依存ライブラリを使いました。FFmpeg、libplacebo、libass、LuaJIT、MuJS、zimg、rubberband、uchardet、Vulkan/MoltenVK関連パッケージなどです。

## ソース取得

```sh
mkdir -p /Users/mba2026/Documents/codex_hisyo/開発/アプリ/VideoReviewPlayer/build-src
git clone https://github.com/mpv-player/mpv.git \
  /Users/mba2026/Documents/codex_hisyo/開発/アプリ/VideoReviewPlayer/build-src/mpv
cd /Users/mba2026/Documents/codex_hisyo/開発/アプリ/VideoReviewPlayer/build-src/mpv
git switch --detach v0.41.0
```

## Configure

最初に成功したビルドでは、ローカルのMesonビルドディレクトリを使いました。

```sh
meson setup build/mpv-r-arm64-local \
  -Dprefix=/Users/mba2026/Documents/codex_hisyo/開発/アプリ/VideoReviewPlayer/build-src/out/mpv-arm64 \
  -Dlibmpv=true \
  -Dobjc_args=-Wno-error=deprecated-declarations \
  -Dgl=enabled \
  -Diconv=enabled \
  -Dlcms2=enabled \
  -Dlua=luajit \
  -Djpeg=enabled \
  -Dplain-gl=enabled \
  -Dzlib=enabled \
  -Dcocoa=enabled \
  -Dcoreaudio=enabled \
  -Dgl-cocoa=enabled \
  -Dvideotoolbox-gl=enabled \
  -Dvideotoolbox-pl=enabled \
  -Dswift-build=enabled \
  -Dmacos-cocoa-cb=enabled \
  -Dmacos-media-player=enabled \
  -Dmacos-touchbar=enabled \
  -Dvulkan=enabled
```

## Compile

Swift/Cocoaのmodule cache書き込みは、compilerがworkspace外へ書こうとすると失敗することがあります。build tree内のcache directoryを使います。

```sh
mkdir -p build/clang-module-cache build/swift-module-cache

CLANG_MODULE_CACHE_PATH="$PWD/build/clang-module-cache" \
SWIFT_MODULE_CACHE_PATH="$PWD/build/swift-module-cache" \
meson compile -C build/mpv-r-arm64-local -j4
```

## Bundle

macOS app bundleを生成します。

```sh
CLANG_MODULE_CACHE_PATH="$PWD/build/clang-module-cache" \
SWIFT_MODULE_CACHE_PATH="$PWD/build/swift-module-cache" \
meson compile -C build/mpv-r-arm64-local macos-bundle
```

生成されたappは以下です。

```sh
build/mpv-r-arm64-local/mpv.app
```

## Verify

```sh
file build/mpv-r-arm64-local/mpv
build/mpv-r-arm64-local/mpv --version
file build/mpv-r-arm64-local/mpv.app/Contents/MacOS/mpv
codesign --verify --deep --strict --verbose=2 \
  build/mpv-r-arm64-local/mpv.app
```

期待される主な結果:

- `Mach-O 64-bit executable arm64`
- `mpv v0.41.0`
- bundle stepが生成したad-hoc署名で、code signing verificationに成功する

Terminalから `mpv.app/Contents/MacOS/mpv --version` を直接実行すると、Cocoa application registrationの初期化によりabortすることがあります。app bundleはFinderまたは `open` 経由でテストします。

## mpv_rとしてパッケージする

Mac用パッケージングスクリプトは、ローカルでビルドした `mpv.app` をsource appとして利用できます。

```sh
VERSION=v0.3-arm64-test \
MAC_SOURCE_APP=/Users/mba2026/Documents/codex_hisyo/開発/アプリ/VideoReviewPlayer/build-src/mpv/build/mpv-r-arm64-local/mpv.app \
packaging/scripts/build-mac.sh
```

これにより以下が生成されます。

```sh
dist/mpv_r-mac-v0.3-arm64-test.zip
```

このスクリプトはbundleを `mpv_r.app` にリネームし、mpv_rのアイコンと設定を注入し、bundle nameとbundle identifierを設定し、documentsをコピーして、生成されたappにad-hoc署名します。

## 未確認事項

- arm64自前ビルドは、日常の動画チェック作業で安定しているか。
- 長い動画や実際の制作用プレイリストで正しく動作するか。
- スクリーンショットの挙動は以前のmpv_r buildと一致しているか。
- Mac Preview系をv1.0前にApple Silicon自前ビルドへ移行すべきか。
- Intel Mac対応はmpv_rでは引き続き対象外でよいか。

