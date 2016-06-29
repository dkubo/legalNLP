#coding:utf-8
#取得した裁判詳細データをアトミックアップデータとしてファイル作成

require 'sqlite3'
#審級判断
#require './clustering/sinkyu.rb'
#裁判年大分類
require './atomic_update/extract_code/class/nendai.rb'
#ソートして出力
#require '/opt/solr_test_server/sort_hanketubun.rb'
#日時データを数値データ変換
require './atomic_update/extract_code/class/sort_date.rb'
#親裁判所
require './atomic_update/extract_code/class/parent_court.rb'
#参照法条修正
require './atomic_update/extract_code/class/ref_fix.rb'
#事件記録符号
require './atomic_update/extract_code/class/jiken_kiroku_hugo.rb'
#アトミックファイル作成
#require '/opt/atomic_update/create_atomic.rb'

#パス定義
FILE_ROOT = ARGV[0]
#REGI_ROOT = ARGV[1]
PATTERN = '**/**/**/*.csv'
DB_NAME='/home/daiki/デスクトップ/hanrei/hanreiDB'

#TUSYOU_ROOT = ARGV[2]
#-------------------------------
#桁数カウント
def calc_digit(f_name)
	return f_name.to_s.length
end

#詳細データファイル名→判決文ファイル名
def name_change(f_name)
	#桁数取得
	digit = calc_digit(f_name)
	case digit
	when 1 then
		f_name = '00000'+ f_name
	when 2 then
		f_name = '0000'+ f_name
	when 3 then
		f_name = '000'+ f_name
	when 4 then
		f_name = '00'+ f_name
	when 5 then
		f_name = '0'+ f_name
	end
	return f_name
end

#################################################
#					main
#################################################
#sort_hanketubun = Sort_Hanketubun.new()
#詳細データ読み込み
Dir.chdir(FILE_ROOT)
Dir.glob(PATTERN) do |file|	
	meta_hash = {}	#メタデータをハッシュ化してストア
	#---------フラグ一覧----------------
	kenri_frg = 0
	sosyou_frg = 0
	bunya_frg = 0
	kenri_frg = 0
	saibansyo_frg = 0
	kekka_frg = 0
	houjou_frg = 0
	saiban_syubetu_frg = 0
	jiken_name_frg = 0
	jiken_num_frg = 0
	saiban_date_frg = 0
	gensin_date_frg = 0
	gensin_num_frg = 0
	gensin_saiban_name_frg = 0
	gensin_kekka_frg = 0
	hanreisyu_frg = 0
	kosai_hanreisyu_frg = 0
	hanji_frg = 0
	yosi_frg = 0
	syubun_frg = 0
	riyu_frg = 0
	mokuji_frg = 0
	bessi_frg = 0
	#-----------------------------------
#	sinkyu = ''
	parent_date = ''
	f_name = file.split("/")[-1].delete('.csv')
#	id = name_change(f_name)
	id = f_name
	#詳細データオープン
	f = open(file,'r')
	f.each_line{|line|
		#xmlタグ消去
		new_line = line.chomp.gsub(/<("[^"]*"|'[^']*'|[^'">])*>/,'').strip()
		#全文かきたらブレイク
		if '全文' == new_line then
			break
		elsif "" == new_line then
			next
		end
#		puts new_line
	#################################################
	#					メタ情報取得
	#################################################
		if kenri_frg == 1# and /&thinsp;/ =~ new_line
#			meta_hash['kenri_syubetu'] = new_line.delete('&thinsp;')
			meta_hash['rightType'] = new_line.delete('&thinsp;')
			kenri_frg = 0
		elsif sosyou_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['litigationType'] = new_line.delete('&thinsp;')
#			meta_hash['sosyou'] = new_line.delete('&thinsp;')
			sosyou_frg = 0
		elsif bunya_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['area'] = new_line.delete('&thinsp;')
#			meta_hash['bunya'] = new_line.delete('&thinsp;')
			bunya_frg = 0
		elsif saibansyo_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['courtName'] = new_line.delete('&thinsp;')
#			meta_hash['court_name'] = new_line.delete('&thinsp;')
			saibansyo_frg = 0
		elsif kekka_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['trialResult'] = new_line.delete('&thinsp;')
#			meta_hash['result'] = new_line.delete('&thinsp;')
			kekka_frg = 0
		elsif houjou_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['referenceLaw'] = new_line.delete('&thinsp;')
#			meta_hash['ref'] = new_line.delete('&thinsp;')
			houjou_frg = 0
		elsif saiban_syubetu_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['trialType'] = new_line.delete('&thinsp;')
#			meta_hash['court_syubetu'] = new_line.delete('&thinsp;')
			saiban_syubetu_frg = 0
		elsif jiken_name_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['incidentName'] = new_line.delete('&thinsp;')
#			meta_hash['accident_name'] = new_line.delete('&thinsp;')
			jiken_name_frg = 0
		elsif jiken_num_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['incidentNum'] = new_line.delete('&thinsp;')
#			meta_hash['accident_num'] = new_line.delete('&thinsp;')
			jiken_num_frg = 0
		elsif saiban_date_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['trialDate'] = new_line.delete('&thinsp;')
#			meta_hash['date'] = new_line.delete('&thinsp;')
			saiban_date_frg = 0
		elsif gensin_date_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['originalDate'] = new_line.delete('&thinsp;')
#			meta_hash['gensin_date'] = new_line.delete('&thinsp;')
			gensin_date_frg = 0
		elsif gensin_num_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['originalincidentNum'] = new_line.delete('&thinsp;')
#			meta_hash['gensin_num'] = new_line.delete('&thinsp;')
			gensin_num_frg = 0
		elsif gensin_saiban_name_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['originalcourtName'] = new_line.delete('&thinsp;')
#			meta_hash['gensin_court_name'] = new_line.delete('&thinsp;')
			gensin_saiban_name_frg = 0
		elsif gensin_kekka_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['originalResult'] = new_line.delete('&thinsp;')
#			meta_hash['gensin_result'] = new_line.delete('&thinsp;')
			gensin_kekka_frg = 0
		elsif hanreisyu_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['CCcollection'] = new_line.delete('&thinsp;')
#			meta_hash['hanrei_syu'] = new_line.delete('&thinsp;')
			hanreisyu_frg = 0
		elsif kosai_hanreisyu_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['HCCcollection'] = new_line.delete('&thinsp;')
#			meta_hash['kosai_hanrei_syu'] = new_line.delete('&thinsp;')
			kosai_hanreisyu_frg = 0
		elsif hanji_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['holding'] = new_line.delete('&thinsp;')
#			meta_hash['hanji'] = new_line.delete('&thinsp;')
			hanji_frg = 0
		elsif yosi_frg == 1# and /&thinsp;/ =~ new_line
			meta_hash['summary'] = new_line.delete('&thinsp;')
#			meta_hash['yosi'] = new_line.delete('&thinsp;')
			yosi_frg = 0
		end
	#################################################
	#					メタ情報マッチ
	#################################################
		if '権利種別' == new_line
			kenri_frg = 1
		elsif '訴訟類型' ==  new_line
			sosyou_frg = 1
		elsif '分野' ==  new_line
			bunya_frg = 1
		elsif '裁判所名'== new_line or '法廷名'== new_line or '裁判所名・部' == new_line
			saibansyo_frg = 1
		elsif '結果' == new_line
			kekka_frg = 1
		elsif '参照法条' == new_line
			houjou_frg = 1
		elsif '事件名' == new_line
			jiken_name_frg = 1
		elsif '裁判種別' == new_line
			saiban_syubetu_frg = 1
		elsif '事件番号' == new_line
			jiken_num_frg = 1
		elsif '裁判年月日' == new_line
			saiban_date_frg = 1
		elsif '原審裁判年月日' == new_line
			gensin_date_frg = 1
		elsif '原審事件番号' == new_line
			gensin_num_frg = 1
		elsif '原審裁判所名' == new_line
			gensin_saiban_name_frg = 1
		elsif '原審結果' == new_line
			gensin_kekka_frg = 1
		elsif '判例集等巻・号・頁' == new_line
			hanreisyu_frg = 1
		elsif '高裁判例集登載巻・号・頁' == new_line
			kosai_hanreisyu_frg = 1
		elsif '判示事項' == new_line
			hanji_frg = 1
		elsif '裁判要旨' == new_line or '判示事項の要旨' == new_line
			yosi_frg = 1
		end
	}
	#################################################
	#					審級判断(裁判所名,原審裁判所名)
	#################################################
#	sinkyu_calc = Sinkyu.new(meta_hash['court_name'],meta_hash['gensin_court_name'])
#	sinkyu = sinkyu_calc.sort
#	if sinkyu != nil
#		meta_hash['sinkyu'] = sinkyu
#	end
	#################################################
	#					裁判年大分類
	#################################################
	nendai_calc = Nendai.new(meta_hash['trialDate'])
	parent_date = nendai_calc.big_sort
	if parent_date != nil
		meta_hash['trialYear_s'] = parent_date
	end
#	#################################################
#	#					裁判年小分類
#	#################################################
	child_date = nendai_calc.small_sort
	if parent_date != nil
		meta_hash['trialYear'] = child_date
	end
#	#################################################
#	#					裁判所大分類
#	#################################################
	analyze_court = Parent_Court.new()
	parent_court = analyze_court.classify(meta_hash['courtName'])
	meta_hash['courtType'] = parent_court
#	#################################################
#	#			判示から通称事件名(存在すれば)を抽出
#	#			事件名から通称事件名(存在すれば)を抽出
#	#################################################
	if meta_hash['holding'] != nil or meta_hash['incidentName'] != nil
		if /（.*事件）/ =~ meta_hash['holding']
			meta_hash['generalincidentName'] = $&.delete('（）いわゆる')
		elsif /（通称）/ =~ meta_hash['incidentName']
			meta_hash['generalincidentName'] = $'.delete('\s　（）')			
		end
	end

#	#################################################
#	#			日時データを数値データへ変換(field:sort_date)
#	#################################################
#	if meta_hash['trialDate'] != nil
#		sort_date = Convert_Date.new()
#		int_date = sort_date.extract_year(meta_hash['trialDate'])
#		meta_hash['intincidentDate'] = int_date
#	end
#	#################################################
#	#					参照法条修正(配列にして返す)
#	#################################################
	if meta_hash['referenceLaw'] != nil
		ref_fix = Ref_Fix.new()
		new_ref = ref_fix.split_ref(meta_hash['referenceLaw'])		#法令データ整形
		meta_hash['referenceLaw'] = new_ref
	end

#	#################################################
#	#			事件記録符号からラベル取得(配列にして返す)
#	#################################################
	if meta_hash['incidentNum'] != nil
		jikenKirokuHugo = Jiken_Kiroku_Hugo.new()
		jikenKirokuHugo.get_hugo(meta_hash['incidentNum'])
		label = jikenKirokuHugo.get_label(meta_hash['courtName'])
		meta_hash['IRCodeArea'] = label
	end
#	puts meta_hash
	###################################
	#				DBに追加
	###################################
#	syubun=escapeStr(syubun)
#	riyu=escapeStr(riyu)
#	#主文
#	db = SQLite3::Database.new(DB_NAME)
	db = SQLite3::Database.new('/home/daiki/デスクトップ/hanrei/hanreiDB')
	for field,value in meta_hash do
		puts id,field,value
		sql="update hanrei set #{field}='#{value}' where id=#{id.to_i}"
		puts sql
		db.execute(sql)
		sql="insert or ignore into hanrei(id,#{field}) values('#{id.to_i}','#{value}')"
		db.execute(sql)
	end

#	#################################################
#	#					アトミックファイル作成
#	#################################################
#	#ファイル名対応付け
#	if meta_hash['ref'] == []
#		meta_hash['ref'] = nil
#	end
#	meta_hash.each{|field_n,field_v|
#		puts field_n,field_v
##		syousai_atomic = Atomic_Update.new()
##		syousai_atomic.set_unique(id)
##		begin
##			#multifieldValued="true"のフィールド
##			if field_n=='ref' or field_n=='jiken_kiroku_num_bunya'
##				for v in field_v do
##					syousai_atomic.set_update(field_n,v)
##				end
##				path = sort_hanketubun.file_analysis(id,REGI_ROOT+field_n+"/")
###			#通称事件名だけ、別のパスへ保存(そのまま登録すると、整合性が合わなくなる場合がある)
###			elsif field_n == 'tusyou_jiken_name' then
###				syousai_atomic.set_update(field_n,v)
###				path = sort_hanketubun.file_analysis(id,TUSYOU_ROOT+field_n+"/")
##			else
##				syousai_atomic.set_update(field_n,field_v)
##				path = sort_hanketubun.file_analysis(id,REGI_ROOT+field_n+"/")
##			end
##			dest = path+id+".xml"
##			syousai_atomic.create_atomic_file(dest)
##		rescue
##			next
##		end
#	}
end



