# macOS v0.3.0 clean-build runtime evidence

This evidence was captured from a new Apple Silicon build of mpv `v0.41.0`
(`41f6a645068483470267271e1d09966ca3b9f413`) on 2026-10-28, using a clean
source checkout and an out-of-tree Meson build directory.

`runtime-manifest.tsv` and `linkage.txt` describe the generated `mpv.app`.
The paired build-input evidence is in `../macos-build-v0.3.0-clean-20261027/`.

## Homebrew evidence

The bundled-runtime Formula/version set is identical to the preserved v0.3.0
audit set. `primary-source-index.tsv` and `source-index.tsv` therefore retain
the already verified upstream archive records for those exact versions.

Three local Homebrew Kegs were no longer present when this clean build was
audited: glib 2.90.1, libunibreak 7.0, and LuaJIT 2.1.1782381659. Their
same-version license texts, receipts, and bottle manifests were copied from
the earlier audit collection. `reused-local-evidence.tsv` records each copied
license file, its SHA-256, and the exact source collection.

The LAME 3.100 bottle retained an installation timestamp but no immutable
Formula revision. The last Homebrew Core commit affecting `Formula/l/lame.rb`
at or before that timestamp is
`54ad61d5ae501840d207f4c3d38447f05751b90d`; its Formula SHA-256 is recorded
in `primary-source-index.tsv`.

This is clean-build evidence, not a published release asset. A release still
needs pre-relocation input hashes and the final mpv_r packaging manifest.
