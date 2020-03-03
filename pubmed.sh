#!/usr/bin/bash

##
# MEDLINEのダウンロードとRDF変換の実行 
##

# プロパティ
WORK=/work
DATA=/data
BASE_URL=ftp://ftp.ncbi.nlm.nih.gov/pubmed/baseline
UPDATE_URL=ftp://ftp.ncbi.nlm.nih.gov/pubmed/updatefiles

# ディレクトリの作成
mkdir -p $WORK/baseline && mkdir -p $WORK/updatefiles

# baselineのダウンロード
cd $WORK/baseline
wget  -r -nd -nc -c -A xml.gz $BASE_URL 2>/dev/stdout

# updatefilesのダウンロード
cd $WORK/updatefiles
wget  -r -nd -nc -c -A xml.gz $UPDATE_URL 2>/dev/stdout

cd / 

# 削除されたPMIDのリスト作成
ls -d $WORK/updatefiles/pubmed*.xml.gz | xargs -P6 -n1 -Ifile ruby pubmed_delete_citation.rb file delete_pmids.txt


# 変換の実行
ls -d $WORK/**/pubmed*.xml.gz | xargs -P3 -n1 -Ifile ruby /pubmed_converter.rb file delete_pmids.txt 

chmod -R 777 $(ls -d $WORK/**/pubmed*.xml.gz) && chmod -R 777 $(ls -d $DATA/pubmed*.ttl)


