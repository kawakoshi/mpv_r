# Windows自前ビルド版：公開前ライセンス確認

このチェックリストは、Windows v0.3.0の自前ビルドランタイムにだけ適用します。テストZIPを公開可能と判断するための関門であり、現時点で公開可能だと主張する文書ではありません。

## 現在の状態

**自前ビルドのWindows ZIPは、まだ公開しません。** テスト用ランタイムにはmpvと、MSYS2のMINGW64ランタイムから集めた100本以上のDLLが入ります。候補ZIPにはmpvのGPL/LGPL文書はありますが、DLLごとの完全なNOTICE・ライセンス一式、および対応ソースの配布場所がまだ揃っていません。

2026-10-30時点で、使用したMSYS2ソースパッケージ86件のアーカイブを取得し、SHA-256を再計算しました。ソース索引では37件を確認済み、残り49件をライセンス確認待ちとしています。当初の確認待ち65件についてはMSYS2アーカイブと上流ソースの対応を照合済みです（通常のアーカイブ56件、コミットを固定したGitソース6件、その他の形式3件）。追加のlibxml2テスト用アーカイブ1件もハッシュを確認しました。65件から抽出したライセンス文書候補220件はすべてハッシュが一致し、内訳はソース直下80件、階層下140件です。階層下の文書が配布DLLに関係するか、同梱すべき表示は何か、引き続きビルド内容と本文を確認します。この段階では公開条件を満たしません。

Windows側の監査フォルダに`remaining-source-audit-summary-v1.tsv`、`remaining-license-candidate-review-v1.tsv`、`remaining-license-candidate-coverage-v1.tsv`を保存しています。残る49件をソース索引の確認済みに変更する前に、PKGBUILD、パッチ、ビルド設定、ライセンス本文を照合します。特に`gcc-libs`、`gettext-runtime`、`libwinpthread`、`librsvg`、`aom`は階層下の文書が複数あり、部品ごとの確認が必要です。

ソース直下の文書80件と配布用ライセンス集を本文のSHAで比較した結果、73件が一致しています。特許表示を含む`lerc`の`NOTICE`は原文のハッシュを確認して追加し、件数表はバックアップを残して更新しました。残る7件（`zstd`、`freetype`、`libgme`、`glib2`、`gcc-libs`、`libwinpthread`、`gettext-runtime`）は一致しません。ソース全体の汎用文書や空ファイルと、DLLに対応する文書が異なる例もあるため、機械的に追加せず実際のビルド対象と照合します。比較結果は`remaining-root-license-staging-v2.tsv`です。

階層下140件のビルド照合では、サンプル・テスト30件、別のgettext分割パッケージ12件、別のソース部品27件、ランタイム部品の文書6件、引き続きビルド対象との照合が必要な65件に分けました（`remaining-nested-license-build-triage-v4.tsv`）。ランタイム部品の6件はすべて配布用文書とSHAが一致します。PCRE2のJITで使うSLJITの文書が不足していたため、原文を追加し件数表をバックアップ付きで更新しました。階層下全体では140件中11件が配布用文書と一致します。残る129件はパスだけで追加・除外を決めません。この一次判定だけではソース索引を変更していません。

その後、本文とビルド内容を確認した10件を2回に分けて確認済みにしました。最初の6件（`brotli`、`libffi`、`libunibreak`、`pixman`、`expat`、`lerc`）はパッケージのパッチと階層下ライセンス候補がなく、ソースアーカイブ、直下の原文、PKGBUILDでの文書配置、配布DLLのインポートを照合しました。次の4件（`pcre2`、`whisper.cpp`、`libtiff`、`libvpl`）はビルド設定、階層下の文書、該当するパッチ、配布DLLのハッシュとインポートを確認しました。PCRE2のJITが使うSLJITの原文は配布用に入っています。libtiffのパッチはヘッダーのインストール一覧、libvplの3パッチはCMakeとpkg-configのインストール設定を変更します。昇格スクリプトは変更前のソース索引を保存し、Windows側に`simple-six-source-verification-v1.tsv`と`reviewed-four-source-verification-v1.tsv`を出力します。

`libpng`もAPNGパッチの出典を調べた後に確認済みにしました。MSYS2収録パッチ（SHA-256 `a9c117324291cda7558ab36bec4ba28a34013d76e1ceaf9953749791a9e154a8`）は、Mozilla Firefoxのコミット`d014e15257f7cebaad4e4d45ffbd25b5959e6ecc`にある`media/libpng/apng.patch`と完全一致します。同じ版の`moz.yaml`はlibpngライセンスと`LICENSE`ファイルを指定し、MSYS2のlibpngソースの`LICENSE`は配布用の原文と一致します。階層下の3件は別にビルドされるcontribプログラムの文書であり、候補ランタイムに入るのは`libpng16-16.dll`だけです。パッチとライセンスの記録、SHA-256表、索引のバックアップ、`libpng-source-verification-v1.tsv`をWindows側の監査フォルダに保存しました。現在のMozilla版やAPNGプロジェクトの1.6.58版パッチは、この履歴上の版と異なります。

続いて`libdatrie`と`fribidi`も確認済みにしました。両方ともパッケージのパッチと階層下のライセンス候補がなく、ソースの`COPYING`は配布用文書と本文のSHAが一致します。PKGBUILDの文書配置、配布DLLのハッシュとインポートを照合しました。変更前の索引と`datrie-fribidi-source-verification-v1.tsv`はWindows側に保存しています。

さらに`SPIRV-Cross`、`liblc3`、`highway`を確認済みにしました。3件ともパッケージ内にパッチがなく、ビルド設定、配布用文書、DLLのハッシュとインポートを照合しています。`liblc3`の階層下にあるPython用LICENSEは直下のLICENSEと本文が一致します。`highway`の`debian/copyright`はApache-2.0を記載した配布メタデータで、配布用の直下LICENSEにはBSD-3-Clauseの選択肢とCC0-1.0の例外も含まれています。階層下文書の判定、変更前の索引、`three-reviewed-libraries-verification-v1.tsv`をWindows側に保存しました。

公開前チェックには、各MSYS2パッケージに対応するライセンス件数表が1行あることと、その件数が実際に配布用へ置いたファイル数と一致することも加えました。今後の文書追加時に件数の更新漏れを検出します。

`libshaderc_shared.dll`はMSYS2の`shaderc 2026.2-1`バイナリパッケージ内のDLLとSHA-256が一致します。そのパッケージの`.BUILDINFO`には、ビルド時の依存として`glslang 16.2.0-3`、`spirv-tools 3~1.4.350.0-1`、`spirv-headers 2~1.4.350.0-1`が記録されています。現在Windowsに入っているglslangとSPIRV-Toolsは後の版なので、このDLLの根拠には使いません。当時の3件のMSYS2ソース・バイナリアーカイブ、SHA-256、`.SRCINFO`に記載された上流ソースのハッシュ、ライセンス原文をWindows側の`shaderc-static-build-dependencies-v1/`と`shaderc-static-dependency-verification-v1/`に保存しました。3件のライセンス原文はshadercの配布用文書へ追加済みです。公開前チェックで版とハッシュを検査し、ZIPには照合表とshadercの`.BUILDINFO`を含めます。このDLLはglslangやSPIRV-ToolsのDLLをインポートせず、内部にglslang 16.2.0の文字列があります。ビルド処理と合わせ、これらのコードがshaderc DLLに取り込まれている根拠として扱います。

公開中のWindows v0.2.0 ZIPは第三者ビルドを使う別のリリースであり、このチェックリストの対象外です。

## リリースごとに確定保存する証跡

対象のビルドマシン・ビルド日時ごとに、リポジトリまたはRelease assetsへ次を残します。

1. mpvのソースタグとコミット。現候補は`v0.41.0`／`41f6a645068483470267271e1d09966ca3b9f413`。
2. Mesonのオプション、コンパイラ・Meson・Ninjaのバージョン、ビルドログ。
3. コピーするDLLを決めた`ldd`出力。
4. 各DLLの所有MSYS2パッケージと`pacman -Q`出力。
5. パッケージアーカイブ名、バージョン、配布元URL、SHA-256。
6. 最終ZIP内の全`.exe`／`.dll`とSHA-256のマニフェスト。

## ZIPに入れるライセンス・ソース情報

公開前に、ZIPの`documents/LICENSES/windows-selfbuild/`へ次を作成します。

- 同梱DLLをMSYS2パッケージ、バージョン、配布元／ソースURL、宣言ライセンスへ対応付けた機械可読マニフェスト。
- 対象MSYS2パッケージにインストールされているライセンス文。
- mpvのライセンスと著作権表示。
- mpvと各依存ライブラリの、実際に使ったソースアーカイブを特定できるソース一覧。
- このリリースで使ったビルド・パッケージングスクリプト。

GPL対象のバイナリは、バイナリと同等以上に利用しやすい場所で完全な対応ソースを提供するか、適用されるGPLが許す別の方法を選びます。単に上流の最新ブランチへリンクするだけでは不十分で、配布バイナリと対応するソースでなければなりません。

MSYS2ではパッケージのライセンス情報を管理し、多くのライセンス文を`<prefix>/share/licenses/<package>/`へ配置します。DLL名から推測せず、実際に使ったパッケージの文書を保存します。

## 公開判定

以下をレビュー担当者がすべて確認できるまで、Windows v0.3.0 ZIPをアップロードしません。

- 全ランタイムファイルがマニフェストにある。
- 各ファイルのパッケージ／ソースとライセンスを特定済み。
- 必要なNOTICEとライセンス文がZIPに入っている。
- 公開する場所から対応ソースに実際にアクセスできる。
- `NOTICE`、`LICENSES/source-and-build-info.txt`、リリースノートが、第三者ビルドではなく自前ビルドのWindowsランタイムを正しく説明している。
- 最終ZIPとマニフェストのSHA-256が、アップロードするassetと一致する。

英語原文：[docs/windows-selfbuild-license-audit.md](../docs/windows-selfbuild-license-audit.md)
