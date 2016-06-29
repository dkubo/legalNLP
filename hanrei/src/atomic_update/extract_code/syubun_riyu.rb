#coding:utf-8
#判決文を「主文」と事実及び理由に分けるコード
#sqliteにプッシュする
require 'sqlite3'

def escapeStr(str)
	str=str.gsub(/'/,"''")
#	str="'"+str+"'"
	return str
end
#############################################
#					main
#############################################
DB_NAME='/home/daiki/デスクトップ/hanrei/hanreiDB'
FILE_ROOT = ARGV[0]
#REGI_ROOT = ARGV[1]
PATTERN = '**/**/**/*.csv'
fail_list = []
Dir.chdir(FILE_ROOT)
#registファイルオープン
Dir.glob(PATTERN) do |file|
	#オブジェクト生成
#	syubun_atomic = Atomic_Update.new()
#	riyu_atomic = Atomic_Update.new()
	f = open(file,"r")
	id = file.split('/')[-1].delete(".csv")
	syubun = ''			#主文
	riyu = ''			#事実及び理由
	syubun_frg = 0
	riyu_frg = 0
	mokuji_frg = 0
	error_frg = 0
	f.each_line{|line|
		match_line = line.delete("\s　").chomp		#文章中の空白消去
        match_line.gsub!("&","＆")
        match_line.gsub!("<","＜")
        match_line.gsub!(">","＞")
		begin
            if /[0-9]{1,3}/ =~ match_line
                if $' == ""
                    next
                end
            end
            
            if /\- [0-9]* \-/ =~ line
                next
            end
            
			if syubun_frg == 0
				if /主文/ =~ match_line.delete("○（）()")
#					syubun += "主文"+"\n"				#「主文」の文言は、スペースを消去して登録
					syubun_frg = 1
					next				#マッチしたらコンティニュー
				end
			elsif syubun_frg == 1 and riyu_frg == 0
				if(/^(事実及び理由|(\(|（)罪となるべき事実|犯行に至る経緯(\)|）)|【理由】|２理由要旨|理由１|理由第１|第１|理由|事実|理由の要旨|事実及び争点|仮処分命令申請書)/ =~ match_line.delete("○"))
					if $& == '第１'
						riyu += match_line
					else
						riyu += $&+"\n"			#「事実及び理由」の文言は、スペースを消去して登録
					end
					riyu_frg = 1
					next				#マッチしたらコンティニュー
				end
				if /\-[0-9]*\-/ =~ match_line
					next
				else
					syubun += line.lstrip.gsub(/^　*/,'')
				end
			elsif riyu_frg == 1 and mokuji_frg == 0
				if /^目次/ =~ match_line.delete("\s　─")
					mokuji_frg = 1
				elsif /\-[0-9]{1,3}\-/ =~ match_line
					next
				else
					riyu += line.lstrip.gsub(/^　*/,'')			#左端のスペースは消去して登録(それ以外のスペースはそのまま登録)
				end
			end
		rescue
			puts "error!!!!!!!!!!"
			error_frg = 1
		end
		#エラーもしくは主文・理由が空の場合、リストに格納
		if riyu == '' or error_frg == 1
			fail_list.push(file)
		end
	}
	###################################
	#				タグ「<〜>」消去
	###################################
	riyu = riyu.gsub(/<.*>/,"")
	###################################
	#			「&」を「&amp;」に変換
	###################################
	riyu = riyu.gsub(/&/,'&amp;')
	riyu = riyu.delete("\s")			#文中に空白があると、うまく形態素解析できないから、空白消去
	###################################
	#				DBに追加
	###################################
	syubun=escapeStr(syubun)
	riyu=escapeStr(riyu)
	#主文
	db = SQLite3::Database.new(DB_NAME)
	sql="update hanrei set syubunPart='#{syubun}' where id=#{id.to_i}"
	db.execute(sql)
	puts "aaaaaaaaaaaaaaaaaaaaaaaaa"
	sql="insert or ignore into hanrei(id,syubunPart) values('#{id.to_i}','#{syubun}')"
	db.execute(sql)
#	#事実及び理由
	sql="update hanrei set riyuPart='#{riyu}' where id=#{id.to_i}"
	db.execute(sql)
	sql="insert or ignore into hanrei(id,riyuPart) values('#{id.to_i}','#{riyu}')"
	db.execute(sql)
	db.close

#	#アトミックアップデートファイル作成
#	syubun_atomic.set_unique(id)
#	syubun_atomic.set_update("syubun",syubun)
#	path = sort_hanketubun.file_analysis(id,REGI_ROOT+"syubun/")
#	dest = path+id+".xml"
#	syubun_atomic.create_atomic_file(dest)
#	riyu_atomic.set_unique(id)
#	riyu_atomic.set_update("riyu",riyu)
#	path = sort_hanketubun.file_analysis(id,REGI_ROOT+"riyu/")
#	dest = path+id+".xml"
#	riyu_atomic.create_atomic_file(dest)
end
#puts fail_list

