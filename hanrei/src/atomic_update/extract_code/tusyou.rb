#coding:utf-8
#通称事件名をアトミックアップデート
require 'nokogiri'

require '/opt/atomic_update/create_atomic.rb'
require '/opt/solr_test_server/sort_hanketubun.rb'
F_PATH = '/opt/civil.csv'		#通称事件名リストファイルパス
#SOURCE = '/opt/atomic_update/26_9_17_to_27_3_5/tusyou/'
SOURCE = '/opt/atomic_update/other/tusyou_jiken_name/'
sort_hanketubun = Sort_Hanketubun.new()
file = open(F_PATH,"r")
file.each_line{|l|
	cnt = 0
	source_array = []
	last_array = []
	total = ''
	tusyou_atomic = Atomic_Update.new()
	array = l.chomp.split(",")
	id = array[0]
	iti = id[0,2]
	ni =  id[2,1]
	array.shift			#array:追加する通称事件名のリスト
	source_path = SOURCE+iti+"/"+ni+"/"+id+".xml"

	#重複チェク
	if File.exist?(source_path) == true
		sfile = open(source_path,"r")
		xml_doc = Nokogiri::XML(sfile)
		field = xml_doc.xpath("//field[@name='tusyou_jiken_name']")
		field.each{|t|
			tusyou = t.inner_text
			source_array.push(tusyou)
			tmp4 = source_array+array
			last_array = tmp4.uniq		#重複除去
		}
	#もともとファイルが存在しない場合
	else
		last_array = array
	end
	#アトミックファイル作成
	tusyou_atomic.set_unique(id)
	for i in last_array do
		tusyou_atomic.set_update("tusyou_jiken_name",i)
	end
	path = sort_hanketubun.file_analysis(id,SOURCE)
	dest = path+id+".xml"
	tusyou_atomic.create_atomic_file(dest)
}

