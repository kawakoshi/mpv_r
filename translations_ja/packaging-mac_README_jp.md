# macOSパッケージングメモ 日本語参考訳

注意：この文書は日本語での確認を助ける参考訳です。正式な内容は`packaging/mac/README.md`を優先してください。

## v0.3.0 Macパッケージ

Mac／Windows共通のv0.3.0 Previewのうち、Mac版はApple Siliconを対象とし、DMGで配布します。

```text
mpv_r.app
Applications -> /Applications
```

レビュー用設定とプロジェクト文書は、次の場所へ収録します。

```text
mpv_r.app/Contents/Resources/
  mpv.conf
  input.conf
  documents/
```

## ビルド

文書化された手順で自前ビルドしたarm64版`mpv.app`を入力に使います。

```sh
VERSION=v0.3.0 \
BUILD_DMG=1 \
MAC_SOURCE_APP=/path/to/mpv.app \
packaging/scripts/build-mac.sh
```

スクリプトは`mpv_r.app`をad-hoc署名し、DMGを作成してSHA-256を表示します。notarizeは行いません。v0.3.0のMac対象はApple Silicon／arm64だけです。

## 公開前チェック

1. 最終DMGに対して`docs/smoke-test-mac.md`を実行します。
2. 最終DMGのSHA-256を`RELEASE_NOTES_v0.3.0.md`へ記録します。
3. `mpv_r-mac-v0.3.0.dmg`を、別途検証したWindows v0.3.0 assetsと同じReleaseで公開します。

ファイル名固有のGatekeeper手順を説明するスクリーンショットには、制作情報を含まない承認済みサンプル動画を使います。
