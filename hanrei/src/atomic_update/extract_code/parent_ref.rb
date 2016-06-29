#coding:utf-8
#参照法条の親分類を参照
#※ほとんどマッチしないので、有斐閣略称一覧を使って変換する必要あり
#	→有斐閣とe-govの略称一覧をハッシュ化した
#→辞書型にする(例：synonym_dict["刑訴法"] = "刑事訴訟法")
#正規表現による一部マッチでは、誤った分類をされてしまう場合があるので、完全マッチを採用
#大階層しかアトミックファイル作成出来てない
#<dynamicField name="*Ref" type="string" indexed="true" stored="true" multiValued="true"/>

require 'nokogiri'
require '/opt/atomic_update/create_atomic.rb'
require '/opt/solr_test_server/sort_hanketubun.rb'
require '/opt/atomic_update/extract_code/class/tree.rb'
require '/opt/atomic_update/extract_code/class/zen_to_i/zen_to_i'

HOREI_LIST = '/home/daiki/デスクトップ/intron/clustering/houjou_kaisou.txt'
SYNONYM_PATH = '/opt/solr_test_server/synonyms/yuhikaku.txt'
#FILE_ROOT = '/opt/atomic_update/meta_data/'
#REGI_ROOT = FILE_ROOT+"parent_ref/"
FILE_ROOT = ARGV[0]
REGI_ROOT = ARGV[1]

PATTERN = '**/**/*.xml'

################################
#			シノニム辞書読込
################################
frg = 0
synonym_dict = {}
synonym = open(SYNONYM_PATH,'r')
synonym.each_line{|s|
	#e-govと有斐閣は略称の位置が逆なので、場合分け
	if /#e-gov/ =~ s or frg == 1
		frg = 1
		tmp = s.chomp.split(',')
		synonym_dict[tmp[-1]] = tmp[0]
	else
		tmp = s.chomp.split(',')
		synonym_dict[tmp[0]] = tmp[1]
	end
}

#		tree_dic(key:大階層,value:中階層)
#		tree_dic2(key:中階層,value:小階層)
tree = Create_Tree.new()
#木構造割り当て
tree_dic,tree_dic2 = tree.create(HOREI_LIST)
puts tree_dic2

#refファイル参照
Dir.chdir(FILE_ROOT)
Dir.glob(PATTERN) do |file|
	p "-------------------------------"
	sort_hanketubun = Sort_Hanketubun.new()
	parent_ref_atomic = Atomic_Update.new()
	ref_array = []
	refMatch = ''		#マッチした参照法条(フィールド名割り当てて登録する)
	sml = ''
	mid = ''
	big = ''
	smlArray = {}			#重複除去用配列
	midArray = {}			#重複除去用配列
	bigArray = {}			#重複除去用配列
	refMatchArray = Hash.new{|hash,key| hash[key] = []}
	otherArray = []		#重複除去用配列
	ref_index = ''
	id = file.split("/")[-1].delete(".xml")
	p "id:"+id
	parent_ref_atomic.set_unique(id)
	file = open(file,"r")
	xml_doc = Nokogiri::XML(file)
	field = xml_doc.xpath("//field[@name='ref']")
	field.each{|t|
		ref_array.push(t.inner_text)
	}
	if ref_array.length != 0 then
		for ref in ref_array do
			big_index = ''
			mid_index = ''
			sml_index = ''
			#数字以降を消去	(例：民法166条1項→民法)
			if /([1-9１-９]|（|\()/ =~ ref#.zen_to_i
				match_ref = $`		#マッチング用のref
			else
				match_ref = ref
			end
			buff = match_ref
			#########################
			#			シノニム適用
			#########################
			match_ref = synonym_dict[match_ref]
			if match_ref == nil
				match_ref = buff
			end
		###################################################
		#						階層参照(第四階層以降は無視)
		#						※先頭のデータを、第三階層とする
		###################################################
			hfile = open(HOREI_LIST,'r')
			hfile.each_line{|h|
				harray = h.chomp.split(',')
				#法令マッチ
				if harray[0] == match_ref then
					#大階層のみデータがある場合
					if harray.length == 2 then
						refMatch = harray[0]
						big = harray[1]
						mid = harray[0]
						sml = ""
					#中階層までデータがある場合
					elsif harray.length == 3 or harray.length == 4 then
						refMatch = harray[0]
						big = harray[1]
						mid = harray[2]
						sml = harray[0]
#					#小階層までデータがある場合
#					elsif harray.length == 4 then
#						refMatch = harray[0]
#						big = harray[1]
#						mid = harray[2]
#						sml = harray[3]
					end
					if big != nil then
						for tmp2 in tree_dic do
							big_index = tmp2[0][big].to_s		#インデックス参照
						end
						bigArray[big_index] = big
						if mid != nil then
							for tmp2 in tree_dic do
								mid_index = tmp2[1][mid].to_s		#インデックス参照
							end
							midArray[mid_index] = mid
							if sml != nil then
								for tmp2 in tree_dic2 do
									sml_index = tmp2[1][sml].to_s		#インデックス参照
								end
								smlArray[sml_index] = sml
							end
						end
					end
					if mid_index == ""
						refMatchArray[big_index].push(ref)
					elsif sml_index == ""
						refMatchArray[big_index+"_"+mid_index].push(ref)
					else
						refMatchArray[big_index+"_"+mid_index+"_"+sml_index].push(ref)
					end
				end
			}
		end
	end	#ref読込終了

#マッチしなかった法令：otherArray
	for index,refMatch in refMatchArray do
		for ref in refMatch do
			if ref_array != nil
				ref_array.delete(ref)
			end
		end
	end
	otherArray = ref_array
	p bigArray
	p midArray
	p smlArray
	p refMatchArray
	p otherArray
################################
#				大階層登録
################################
	if bigArray != nil then
		for index,big in bigArray do
			if big != ""
				parent_ref_atomic.set_update(index.to_s+"_bigRef",big)
###				parent_ref_atomic.setDeleteUpdate(index.to_s+"_bigRef")		#デリートする用

			end
		end
	end
#################################
#				中階層登録
#################################
	if midArray != nil
		for index,mid in midArray do
			if mid != ""
				parent_ref_atomic.set_update(index.to_s+"_midRef",mid)	
###				parent_ref_atomic.setDeleteUpdate(index.to_s+"_midRef")		#デリートする用

			end
		end
	end
#################################
#				小階層登録
#################################
	if smlArray != nil
		for index,sml in smlArray do
			if sml != ""
				parent_ref_atomic.set_update(index.to_s+"_smlRef",sml)
###				parent_ref_atomic.setDeleteUpdate(index.to_s+"_smlRef")		#デリートする用
			end
		end
	end
#################################
#				マッチした法令
#################################
	if refMatchArray != nil
		for index,refMatch in refMatchArray do
			for ref in refMatch do
				if refMatch != ""
					parent_ref_atomic.set_update(index.to_s+"_Ref",ref)
###					parent_ref_atomic.setDeleteUpdate(index.to_s+"_refMatchRef")		#デリートする用
				end
			end
		end
	end
#################################
#			マッチしなかった法令登録
#################################
	if otherArray != nil
		for other in otherArray do
			if other != ""
				parent_ref_atomic.set_update("otherRef",other.to_s)
###				parent_ref_atomic.setDeleteUpdate("otherRef")		#デリートする用
			end
		end
	end
	################################
	#		アトミックファイル作成
	################################
	path = sort_hanketubun.file_analysis(id,REGI_ROOT)
	dest = path+id+".xml"
	parent_ref_atomic.create_atomic_file(dest)
end		#1ファイル読込終了

