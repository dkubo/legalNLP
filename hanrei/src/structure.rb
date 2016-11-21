#coding:utf-8
#判決文を構造化する
#作成者 : magunesium
#作成日 : 2014/8/?
#主文：一とか二とかはいらない(主文の中身とかはいらない)
#事実及び理由：第3階層までとにかく抽出する
#とにかく精度を上げる

require './atomic_update/extract_code/class/mokuji_class.rb'
require './sqlite3.rb'

##########################################
#						main
##########################################
DB_PATH = "../data/hanreiDB"
mokuji_fail = []					#目次作成に失敗したファイルリスト
db = SQLight3.new(DB_PATH)
sql = "select id, syubunPart, riyuPart from hanrei"
cursorID = db.executeSQL(sql)
cursorID.each do |tuple_id|
	puts "---------------------------------------"
	index_gen = Index_Gen.new()
	syubun_frg = 0						#主文フラグ
	riyu_frg = 0							#理由フラグ
	error_frg = 0							#エラーフラグ
	pattern = 0
	last_frg = 0
	first_pattern = ''
	second_pattern = ''
	mokuji = ''
	kaisou_one_list = []			#階層番号保存用リスト
	kaisou_two_list = []			#階層番号保存用リスト
	id = tuple_id[0]
	syubun = tuple_id[1].split("\n")
	riyu = tuple_id[2].split("\n")
	text = syubun + riyu
	for line in riyu
		begin
		if /\・{7,100}/ =~ line or /\.{7,100}/ =~ line
			puts 'fail to generate index maybe.'
			puts 'you need to check this file:'+file
		end
		#主文の開始取得
		if syubun_frg == 0
			syubun_frg = index_gen.search_syubun(line,syubun_frg)
			next
		end
		#主文部取得&理由の開始取得
		if syubun_frg == 1 and riyu_frg == 0
			riyu_frg = index_gen.search_riyu(line,riyu_frg)
			next
		end
		#理由部取得
		if syubun_frg == 1 and riyu_frg == 1 and last_frg == 0
			first_pattern,second_pattern,pattern,mokuji,kaisou_one_list,kaisou_two_list,last_frg = index_gen.get_riyu_index(line,first_pattern,second_pattern,pattern,kaisou_one_list,kaisou_two_list,last_frg)
			next
		end
		rescue => ex
			puts ex.message
			error_frg = 1
		end
	end
	#####################################################
	#					目次番号チェック(階層1)
	#####################################################
	#kaisou_one_list : [1,2,3,4,5,....]
	pre = 0
	for num in kaisou_one_list
		if num == nil
			error_frg = 1
		elsif num.to_i != 1
			if (num - pre != 1)
				error_frg = 1
			#構造の順番が正しい場合
			else
				pre = num
			end
		#num = 1の場合
		elsif num == 1 and pre != 1
				pre = num
		#[1,1,1,1]がエラーになるようにする
		elsif pre == 1 and num == 1
			error_frg = 1
		end
	end
	#####################################################
	#					目次番号チェック(階層2)
	#####################################################
	#kaisou_two_list : [1,2,3,4,1,2,3,...]
	#p "階層２：#{kaisou_two_list}"
	pre = 0
	for num in kaisou_two_list
		if num == nil
			error_frg = 1
		elsif num.to_i != 1
			if (num - pre != 1)
				error_frg = 1
			#構造の順番が正しい場合
			else
				pre = num
			end
		#num = 1の場合
		elsif num == 1 and pre != 1
				pre = num
		#[1,1,1,1]がエラーになるようにする
		elsif pre == 1 and num == 1
			error_frg = 1
		end
	end
	if syubun_frg == 0 or riyu_frg == 0
		error_frg = 1
	end
	p id, mokuji.split("\n")
end
