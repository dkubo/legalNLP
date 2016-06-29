#coding:utf-8
#判決文を構造化する
#作成者 : magunesium
#作成日 : 2014/8/?
#主文：一とか二とかはいらない(主文の中身とかはいらない)
#事実及び理由：第3階層までとにかく抽出する
#とにかく精度を上げる

#require '/opt/atomic_update/create_atomic.rb'
require './class/mokuji_class.rb'
#require '/opt/solr_test_server/sort_hanketubun.rb'

##########################################
#						main
##########################################
#SOURCE_ROOT = ARGV[0]
SOURCE_ROOT = "../../../data/text"
#REGI_ROOT = ARGV[1]
PATTERN = '**/**/**/*.csv'
#sort_hanketubun = Sort_Hanketubun.new()
mokuji_fail = []					#目次作成に失敗したファイルリスト
Dir.chdir(SOURCE_ROOT)
#ファイル名の取得
Dir.glob(PATTERN) do |file|
	puts "---------------------------------------"
	puts "ファイル名："+file
	#オブジェクト生成
#	mokuji_atomic = Atomic_Update.new()
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
	#saibankan = []
	f = open(file,"r")
	id = file.delete(".csv")
	#書き込み用ファイルオープン
	#1行ずつ読込み
	f.each_line{|line|
		begin
		if /\・{7,100}/ =~ line or /\.{7,100}/ =~ line
			puts 'this fail to generate index maybe.'
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
	}		#１ファイル読込み終了
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
	puts mokuji
	#アトミックアップデートファイル作成
#	mokuji_atomic.set_unique(id)
#	mokuji_atomic.set_update("mokuji",mokuji)
#	path = sort_hanketubun.file_analysis(id,REGI_ROOT+"mokuji/")
#	dest = path+id+".xml"
#	mokuji_atomic.create_atomic_file(dest)
end
