#!/usr/bin/env bash
set -euo pipefail
e=$1
v=$2
cp "$e/license-manifest.tsv" "$e/license-manifest.pre-promotion.tsv"
cp "$e/source-index.tsv" "$e/source-index.pre-promotion.tsv"
awk -F '\t' 'BEGIN{OFS="\t"} NR==FNR{if(NR>1&&$7=="MSYS2_SOURCE_PACKAGE_VERIFIED")a[$1 FS $2]=$0;next} NR==1{print;next}{k=$1 FS $2;if(k in a){split(a[k],x,FS);$5=x[3];$6=x[4];$7="VERIFIED"}print}' "$v" "$e/source-index.tsv" > "$e/source-index.tsv.new"
mv "$e/source-index.tsv.new" "$e/source-index.tsv"
awk -F '\t' 'BEGIN{OFS="\t"} NR==1{print;next}{cmd="find \"'"$e"'/licenses/"$1"\" -type f 2>/dev/null | wc -l";cmd|getline n;close(cmd);if(n>0){$3=n;$4="COLLECTED"}print}' "$e/license-manifest.tsv" > "$e/license-manifest.tsv.new"
mv "$e/license-manifest.tsv.new" "$e/license-manifest.tsv"
