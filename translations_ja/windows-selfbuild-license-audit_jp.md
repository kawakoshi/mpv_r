# Windows自前ビルド版：公開前ライセンス確認

このチェックリストは、Windows v0.3.0の自前ビルドランタイムにだけ適用します。テストZIPを公開可能と判断するための関門であり、現時点で公開可能だと主張する文書ではありません。

## 現在の状態

**ソースとライセンスの監査は完了しましたが、古い候補ZIPは公開しません。** 監査したランタイムにはmpvと、MSYS2のMINGW64ランタイムから集めた100本以上のDLLが入ります。確認済み証跡からZIPを作り直し、公開先の対応ソースへ実際にアクセスできることと、最終assetのハッシュを検証してから公開します。

2026-10-31時点で、使用したMSYS2ソースパッケージ86件のアーカイブを取得し、SHA-256を再計算しました。MSYS2の86件はすべて確認済みで、mpvを加えたソース索引87行がすべて`VERIFIED`です。当初の確認待ち65件についてはMSYS2アーカイブと上流ソースの対応を照合済みです（通常のアーカイブ56件、コミットを固定したGitソース6件、その他の形式3件）。追加のlibxml2テスト用アーカイブ1件もハッシュを確認しました。65件から抽出したライセンス文書候補220件はすべてハッシュが一致し、内訳はソース直下80件、階層下140件です。その後の部品単位の確認も完了し、統合証跡に対する総合verifierは成功しました。残る公開条件は最終ZIPの生成と公開物の検証であり、未確認のソースパッケージではありません。

Windows側の監査フォルダに`remaining-source-audit-summary-v1.tsv`、`remaining-license-candidate-review-v1.tsv`、`remaining-license-candidate-coverage-v1.tsv`を保存しています。全行についてPKGBUILD、パッチ、ビルド設定、DLLハッシュ、ライセンス本文の照合を完了しました。途中の報告TSVには当時の確認待ち表示が残りますが、最終状態の正本は`source-index.tsv`、各昇格記録、`verify-windows-selfbuild-evidence.sh`の成功結果です。

ソース直下の文書80件と配布用ライセンス集を本文のSHAで比較した結果、73件が一致しています。特許表示を含む`lerc`の`NOTICE`は原文のハッシュを確認して追加し、件数表はバックアップを残して更新しました。この比較時点の不一致7件は`zstd`、`freetype`、`libgme`、`glib2`、`gcc-libs`、`libwinpthread`、`gettext-runtime`でした。ソース全体の汎用文書や空ファイルと、DLLに対応する文書が異なる例もあるため、機械的に追加せず実際のビルド対象と照合します。比較結果は`remaining-root-license-staging-v2.tsv`です。

階層下140件のビルド照合では、サンプル・テスト30件、別のgettext分割パッケージ12件、別のソース部品27件、ランタイム部品の文書6件、引き続きビルド対象との照合が必要な65件に分けました（`remaining-nested-license-build-triage-v4.tsv`）。ランタイム部品の6件はすべて配布用文書とSHAが一致します。PCRE2のJITで使うSLJITの文書が不足していたため、原文を追加し件数表をバックアップ付きで更新しました。階層下全体では140件中11件が配布用文書と一致します。残る129件はパスだけで追加・除外を決めません。この一次判定だけではソース索引を変更していません。

その後、本文とビルド内容を確認した10件を2回に分けて確認済みにしました。最初の6件（`brotli`、`libffi`、`libunibreak`、`pixman`、`expat`、`lerc`）はパッケージのパッチと階層下ライセンス候補がなく、ソースアーカイブ、直下の原文、PKGBUILDでの文書配置、配布DLLのインポートを照合しました。次の4件（`pcre2`、`whisper.cpp`、`libtiff`、`libvpl`）はビルド設定、階層下の文書、該当するパッチ、配布DLLのハッシュとインポートを確認しました。PCRE2のJITが使うSLJITの原文は配布用に入っています。libtiffのパッチはヘッダーのインストール一覧、libvplの3パッチはCMakeとpkg-configのインストール設定を変更します。昇格スクリプトは変更前のソース索引を保存し、Windows側に`simple-six-source-verification-v1.tsv`と`reviewed-four-source-verification-v1.tsv`を出力します。

`libpng`もAPNGパッチの出典を調べた後に確認済みにしました。MSYS2収録パッチ（SHA-256 `a9c117324291cda7558ab36bec4ba28a34013d76e1ceaf9953749791a9e154a8`）は、Mozilla Firefoxのコミット`d014e15257f7cebaad4e4d45ffbd25b5959e6ecc`にある`media/libpng/apng.patch`と完全一致します。同じ版の`moz.yaml`はlibpngライセンスと`LICENSE`ファイルを指定し、MSYS2のlibpngソースの`LICENSE`は配布用の原文と一致します。階層下の3件は別にビルドされるcontribプログラムの文書であり、候補ランタイムに入るのは`libpng16-16.dll`だけです。パッチとライセンスの記録、SHA-256表、索引のバックアップ、`libpng-source-verification-v1.tsv`をWindows側の監査フォルダに保存しました。現在のMozilla版やAPNGプロジェクトの1.6.58版パッチは、この履歴上の版と異なります。

続いて`libdatrie`と`fribidi`も確認済みにしました。両方ともパッケージのパッチと階層下のライセンス候補がなく、ソースの`COPYING`は配布用文書と本文のSHAが一致します。PKGBUILDの文書配置、配布DLLのハッシュとインポートを照合しました。変更前の索引と`datrie-fribidi-source-verification-v1.tsv`はWindows側に保存しています。

さらに`SPIRV-Cross`、`liblc3`、`highway`を確認済みにしました。3件ともパッケージ内にパッチがなく、ビルド設定、配布用文書、DLLのハッシュとインポートを照合しています。`liblc3`の階層下にあるPython用LICENSEは直下のLICENSEと本文が一致します。`highway`の`debian/copyright`はApache-2.0を記載した配布メタデータで、配布用の直下LICENSEにはBSD-3-Clauseの選択肢とCC0-1.0の例外も含まれています。階層下文書の判定、変更前の索引、`three-reviewed-libraries-verification-v1.tsv`をWindows側に保存しました。

続いて`libtasn1`と`libunistring`も確認済みにしました。各パッケージの直下にある2件のライセンス本文が、それぞれ配布用文書と一致します。PKGBUILDが両方を配置すること、配布DLLのハッシュとインポートを照合しました。変更前の索引と`two-gnu-libraries-verification-v1.tsv`はWindows側に保存しています。

`speex`も確認済みにしました。別の著作権表示を持つVorbis心理音響・FFTのソースは、`BUILD_VORBIS_PSY`を有効にした場合だけlibspeexへ入りますが、今回のPKGBUILDは有効にしていません。libspeexのリンク対象は数学ライブラリの設定だけで、配布DLLにはlibogg・speexdspのインポートも該当するシンボル名もありません。ソースの`COPYING`は配布用BSD文書と一致します。判定に使ったソースファイルのハッシュ、DLLのハッシュ、変更前の索引、`speex-source-verification-v1.tsv`をWindows側に保存しました。

`lcms2`も確認済みにしました。MITの本体は`liblcms2-2.dll`、有効なGPL-3.0のfast-floatプラグインは別の`liblcms2_fast_float-2.dll`としてビルドされ、threadedプラグインは無効です。候補ランタイムに入るのは本体DLLだけで、fast-float DLLはランタイム一覧にありません。一方、プラグインのGPL-3.0原文は配布用ライセンス集に収録済みです。ビルド定義、DLLのハッシュとインポート、階層下文書の判定、索引のバックアップ、`lcms2-source-verification-v1.tsv`をWindows側に保存しました。

`xz`も確認済みにしました。ソース直下の5件のライセンス文書はすべて配布用の原文と一致します。上流の`COPYING`では、候補ランタイムに入る唯一のXZ由来DLLであるliblzmaを0BSDとしています。パッケージ内にパッチはなく、PKGBUILDが`COPYING*`をすべて配置すること、DLLのハッシュとインポートも確認しました。変更前の索引と`xz-source-verification-v1.tsv`はWindows側に保存しています。

`ggml`も確認済みにしました。固定GitコミットがMSYS2ソースアーカイブ内にあり、MITの`LICENSE`は配布用原文と一致します。最初の候補ランタイムでは、パッケージが`GGML_BACKEND_DL=ON`と`GGML_CPU_ALL_VARIANTS=ON`でビルドされているにもかかわらず、`ldd`による収集からCPUバックエンド14本がすべて漏れていました。この発見は`ggml-runtime-backend-gap-v1.tsv`に保存しています。

修正後の再ビルドでは`ggml-cpu-*.dll` 14本をすべて収録しました。旧候補からの削除は0件、追加はこの14本だけで、ほかに変化したのは再ビルド対象の`mpv.exe`、`mpv.com`、`libmpv-2.dll`だけです。実ロード試験では登録バックエンドが0件から1件へ増え、`CPU`が登録され、この検査機では`ggml-cpu-icelake.dll`が選択されました。公開前チェックでは最低限の`ggml-cpu-x64.dll`を要求します。旧監査証跡を修正版へ統合するときは、ソースと実行時パッケージの名前・版、mpvコミット、ランタイム差分を検査する`merge-windows-ggml-fixed-evidence.sh`を使います。

修正版証跡への統合後、さらに19件を確認済みにしました。最初の9件はWindows互換やビルド設定を調整する低複雑度パッチ各1件、次の8件はパッチ集合全体の固定ハッシュまで照合しました。FreeTypeは直下の案内文が参照するFTLとGPLv2の本文2件が配布用文書と完全一致します。最後の特殊アーカイブ2件では、libxml2の追加NOTICE 2件がテスト専用であること、gettext-runtimeのランタイム用4文書が完全一致し、残る12文書が別ビルドのtools/libtextstyle分割パッケージに属することを確認しました。変更前の索引と`low-complexity-patched-nine-verification-v1.tsv`、`reviewed-patched-eight-verification-v1.tsv`、`special-runtime-two-verification-v1.tsv`はWindows側に保存しています。

続く9件では、階層下の未判定文書を1件ずつビルド内容と照合しました。libgmeのemu2413、rav1eの既定ivf機能、HarfBuzzのMicrosoft USEデータに対応する3文書は配布用ライセンス集へ原文SHAのまま追加し、件数表をバックアップ付きで更新しました。ほかは直下文書との重複、無効化されたテスト、未収録のデモまたは別分割パッケージ、空文書です。判断は`three-runtime-component-license-staging-v1.tsv`と`single-nested-nine-verification-v1.tsv`に保存しています。

次の7件では、階層下の未判定文書を2件ずつ確認しました。libblurayへ静的に入るlibudfread、SVT-AV1本体が使うfastfeatの文書を追加しました。さらにOpenSSLへコピーされるMSYS2のpathtoolsソースを手作業で確認し、独立LICENSEがなく候補抽出から漏れていたCC0表示を両ソース共通の原文コメントからNOTICEとして追加しました。残りは無効化・ビルド時のみ・de-vendor済み・文書・デモ・別分割パッケージの部品です。`libbluray-svt-openssl-notice-staging-v1.tsv`と`two-nested-seven-verification-v1.tsv`に保存しています。

続く高複雑度5件では、GLibのGVDBと、AOMのfastfeat・vector・x86incの文書を追加しました。これらのソースは配布DLLへ組み込まれます。libjxlのDebianメタデータ・HEVC設定・静的extras、OpenJPEGのviewer・formatter・フォールバックライブラリ、Cairoの無効な性能計測コードと未収録utilityライブラリは、ポータブル版の配布対象から除外しました。GLibのライセンスリンクがWindowsで空ファイルとして抽出されていた件は、固定上流アーカイブからリンク先を読み直し、配布済みLGPL本文との一致を記録しました。`glib-symlink-license-correction-v1.tsv`、`glib-aom-notice-staging-v1.tsv`、`high-complexity-five-verification-v1.tsv`に保存しています。

最後の3件も解決しました。librsvgの空候補7件はアーカイブ内のシンボリックリンクで、5件は配布済みLGPL本文、2件はランタイム依存ではないMITのrebind workspace crateを指すことを確認しました。MinGW-w64 runtime本文は、runtimeの一部を静的リンクしたバイナリパッケージへ通知を収録するよう記載しているため追加しました。libwinpthread自身のMIT/BSD本文は既に完全一致しています。GCCは、配布済みのGPLv3、LGPL、GCC Runtime Library Exception一式が、収録するlibgcc・libgomp・libstdc++ DLLをカバーします。残る候補はコンパイラ、ヘッダー、文書、テスト、未収録ライブラリのものです。`librsvg-symlink-license-correction-v1.tsv`、`final-runtime-notice-staging-v1.tsv`、`final-three-verification-v1.tsv`に保存しています。ソース索引87行はすべて確認済みとなり、総合verifierも成功しました。

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

## 対応ソースassetの作成

ソース索引1行目に記録したmpvの固定コミットtarballを取得した後、次のスクリプトで別assetを作ります。

```sh
packaging/tools/build-windows-corresponding-source.sh \
  /c/path/to/windows-release-evidence \
  /c/path/to/41f6a645068483470267271e1d09966ca3b9f413.tar.gz \
  /c/path/to/mpv_r-windows-v0.3.0-corresponding-source.tar.zst
```

このスクリプトは証跡検証を再実行し、mpv tarballのSHA-256、ソース索引87行、MSYS2ソースパッケージ86件を確認します。さらに現在のmpv_rプロジェクトソースと全収録ファイルのSHA-256を加え、既存assetを上書きせずに最終`tar.zst`を作成します。

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
