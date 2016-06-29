#!/bin/bash
#最高裁から判決文とその裁判の詳細データをスクレイピングしてきて、pdf→テキスト変換する
#テキスト変換データ→様々なメタデータ抽出→Solrポスト
#(通称事件名は今のところ、自動化不能)

#出力パス宣言
readonly ROOT_DIR="/home/daiki/デスクトップ/hanrei"
readonly ATOMIC_PATH="${ROOT_DIR}/meta_data/"
readonly TEXT_PATH="${ROOT_DIR}/text/"		#テキストデータ出力ディレクトリ
readonly SYOUSAI_PATH="${ROOT_DIR}/syousai_data/"		#判決文詳細データ出力ディレクトリ
readonly URL_PATH="${ROOT_DIR}/fix_list.txt"		   		#pdf_urlリスト出力先
readonly PDF_PATH="${ROOT_DIR}/pdf_sources/"					#スクレイピングしたpdf出力ディレクトリ
#readonly PDF_PATH="/media/daiki/HDCA-UT/pdf_sources/"					#スクレイピングしたpdf出力ディレクトリ
readonly CITE_PATH="/${ROOT_DIR}/citation.csv"
readonly CITE_PATH_NEW="/${ROOT_DIR}/citation_new.csv"
readonly CITE_CITED_PATH="/${ROOT_DIR}/cite_cited.csv"
readonly CITE_CITED_PATH_NEW="/${ROOT_DIR}/cite_cited_new.csv"										   		
readonly CITE_ATOMIC_PATH="/${ROOT_DIR}/atomic_update/meta_data/other"										#引用・被引用アトミックファイルディレクトリルート

#保存先ディレクトリ作成
#mkdir ${SYOUSAI_PATH}
#mkdir ${PDF_PATH}
#mkdir ${TEXT_PATH}
#mkdir ${ATOMIC_PATH}
#mkdir ${EXTRACT_TUSYOU_PATH}
#rm ${URL_PATH}

#######################################################
#								判決文取得 フェーズ
#######################################################
#引数：URLリスト出力先,詳細データ出力先,開始年号,開始年,開始月,開始日,終了年号,終了年,終了月,終了日
#ruby ${ROOT_DIR}/saikousai_scraping.rb ${URL_PATH} ${SYOUSAI_PATH} 昭和 22 1 1 平成 28 4 23

#pdfファイル取得
#ruby ${ROOT_DIR}/getPDF.rb ${URL_PATH} ${PDF_PATH}
####for line in `cat ${URL_PATH}`
####do
####	wget -4 ${line} -P ${PDF_PATH}			#-4 : IPv4 だけを使う
####done

#pdf→テキスト変換
#ruby ${ROOT_DIR}/transText.rb ${TEXT_PATH}
#for FILE in ${PDF_PATH}/*.pdf
#do
#	FNAME=`echo ${FILE}|cut -c 62-67`
#	echo $FNAME
#	java -jar tika-app-1.12.jar -t ${FILE} > ${TEXT_PATH}/$FNAME.csv
#done

#######################################################
#								メタデータ抽出 フェーズ
#######################################################
#	主文・理由(第1引数：テキストデータパス,第2引数：出力ルートパス)
#ruby ${ROOT_DIR}/atomic_update/extract_code/syubun_riyu.rb ${TEXT_PATH} ${ATOMIC_PATH}/
#echo "Start syubun_riyu.rb"
#ruby ${ROOT_DIR}/atomic_update/extract_code/syubun_riyu.rb ${TEXT_PATH}
#echo "Finish syubun_riyu.rb"

#目次(第1引数：テキストデータパス,第2引数：出力ルートパス)
#echo "Start mokuji.rb"
#ruby /opt/atomic_update/extract_code/mokuji.rb ${TEXT_PATH} ${ATOMIC_PATH}/
#echo "Finish mokuji.rb"

#賠償金抽出
#echo "Start baisyoukin.rb"
#ruby /opt/atomic_update/extract_code/baisyoukin.rb ${ATOMIC_PATH}/syubun/ ${ATOMIC_PATH}/
#echo "Finish baisyoukin.rb"

#詳細データ等を抽出
	#データ一覧
		#権利種別
		#訴訟類型
		#分野
		#裁判所名
		#結果
		#参照法条
			#整形処理も
		#事件名
		#裁判種別
		#事件番号
		#裁判年月日
			#裁判年に関しては、親子関係も
			#裁判年月日の数値データ化も
		#原審裁判年月日
		#原審事件番号
		#原審裁判所名
		#原審結果
		#判例集等巻・号・頁
		#高裁判例集登載巻・号・頁
		#判示事項
		#裁判要旨
		#事件記録符号に対応する分野
		#通称事件名
			#判示/事件名からの抽出(存在すれば)
#echo "Start syousai.rb"
#ruby /opt/atomic_update/extract_code/syousai.rb ${SYOUSAI_PATH} ${ATOMIC_PATH}/ #${EXTRACT_TUSYOU_PATH}
ruby ${ROOT_DIR}/atomic_update/extract_code/syousai.rb ${SYOUSAI_PATH}
#echo "Finish syousai.rb"

#参照法条の階層化
#echo "Start parent_ref.rb"
#ruby /opt/atomic_update/extract_code/parent_ref.rb ${ATOMIC_PATH}/ref/ ${ATOMIC_PATH}/parent_ref/
#echo "Finish parent_ref.rb"


########################################################
#					SolrへPost フェーズ(引用以外)
########################################################
#サーバ1(本番)
#echo ${ATOMIC_PATH}/**/**/**/*.xml | xargs bash /opt/solr_test_server/leaglessolr/postAzureToDevelop.sh
#サーバ2(開発)
#echo ${ATOMIC_PATH}/**/**/**/*.xml | xargs bash /opt/solr_test_server/leaglessolr2/postAzure2ToDevelop.sh


########################################################
#					引用・被引用抽出＆Solrへポストフェーズ
########################################################
#引用・被引用(アトミックファイル生成先をここに関しては変える)
#1.判決文中から引用抽出(新たな判例に対してのみ実行)
#ruby /opt/atomic_update/extract_code/citation.rb ${ATOMIC_PATH}/riyu/ ${CITE_PATH_NEW}
#1.引用アトミックファイル作成(DB内に存在するしないに関わらず集計:citeAll)
#ruby /opt/atomic_update/extract_code/citeAll.rb ${CITE_PATH_NEW} ${CITE_ATOMIC_PATH}/citeAll/

#2.事件番号→id検索(Solrで),cite_cited.csv生成
#rm ${CITE_CITED_PATH_NEW}	#cite_cited_new.csv更新
#ruby /opt/accident_num_search.rb ${CITE_PATH_NEW} ${CITE_CITED_PATH_NEW} ${CITE_CITED_PATH}  		#既存の引用被引用と統合
#2.(id,id)の引用ファイル生成(新たな判例に対してのみ実行)
#ruby /opt/atomic_update/extract_code/cite_list.rb ${CITE_CITED_PATH_NEW} ${CITE_ATOMIC_PATH}

#3.被引用アトミックファイル生成(全ての判例に対して実行)
#ruby /opt/atomic_update/extract_code/cited_list.rb ${CITE_CITED_PATH} ${CITE_ATOMIC_PATH}

#Solrへポスト(citeAll,cite_list,cited_list)
#サーバ2
#echo ${CITE_ATOMIC_PATH}/citeAll/**/**/*.xml | xargs bash /opt/solr_test_server/leaglessolr2/postAzure2ToDevelop.sh
#echo ${CITE_ATOMIC_PATH}/cite_list/**/**/*.xml | xargs bash /opt/solr_test_server/leaglessolr2/postAzure2ToDevelop.sh
#echo ${CITE_ATOMIC_PATH}/cited_list/**/**/*.xml | xargs bash /opt/solr_test_server/leaglessolr2/postAzure2ToDevelop.sh


