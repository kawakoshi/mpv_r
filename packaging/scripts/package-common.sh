#!/usr/bin/env sh
set -eu

copy_common_documents() {
  root="$1"
  target="$2"

  mkdir -p "$target/documents/LICENSES"
  mkdir -p "$target/documents/translations_ja"

  cp "$root/packaging/common/README.txt" "$target/documents/README.txt"
  cp "$root/packaging/common/NOTICE.txt" "$target/documents/NOTICE.txt"
  cp "$root/LICENSE" "$target/documents/LICENSE.txt"
  cp "$root/docs/shortcuts.md" "$target/documents/shortcuts.md"

  cp "$root/LICENSES/mpv-Copyright.txt" "$target/documents/LICENSES/"
  cp "$root/LICENSES/mpv-LICENSE.GPL.txt" "$target/documents/LICENSES/"
  cp "$root/LICENSES/mpv-LICENSE.LGPL.txt" "$target/documents/LICENSES/"
  cp "$root/LICENSES/source-and-build-info.txt" "$target/documents/LICENSES/"

  cp "$root/translations_ja/packaging-common_README_txt_jp.txt" "$target/documents/translations_ja/README_jp.txt"
  cp "$root/translations_ja/packaging-common_NOTICE_txt_jp.txt" "$target/documents/translations_ja/NOTICE_jp.txt"
  cp "$root/translations_ja/LICENSE_jp.md" "$target/documents/translations_ja/LICENSE_jp.txt"
  cp "$root/translations_ja/source-and-build-info_jp.txt" "$target/documents/translations_ja/source-and-build-info_jp.txt"
  cp "$root/translations_ja/shortcuts_jp.md" "$target/documents/translations_ja/shortcuts_jp.md"
}
