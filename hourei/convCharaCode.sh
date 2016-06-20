#!/bin/bash
#テキスト変換

#文字コード設定
export LANG=ja_JP.UTF-8
#export LANG=ja_JP.eucJP
export LESSCHARSET=utf-8

#echo $LANG
readonly ROOT_PATH="/opt/e-gov/data/html"    #ルートディレクトリ
readonly CONVERT_PLACE="/opt/tmp"      #変換用ディレクトリ
EXTENSION="html"

mkdir -p ${CONVERT_PLACE}
#階層が二種類ある
for FILE in "${ROOT_PATH}"/*."${EXTENSION}"
do
##########################
##  ディレクトリであれば無視
##########################
  IFS=$'/'
	arr=($FILE)
	IFS=$','
	FNAME=${arr[5]}
	mv ${FILE} ${CONVERT_PLACE}/${FNAME}
  nkf -w ${CONVERT_PLACE}/${FNAME} > ${FILE}
  rm ${CONVERT_PLACE}/$FNAME     #変換後、消去
done

