#coding:utf-8
#事実及び理由の部分のみ(記号と数字を消去して)取り出すコード

#---------main----------
FILE_ROOT = '../scraping_data/*.txt'
id = 1
Dir.glob(FILE_ROOT).each{|file|
	id += 1
	f = open(file,"r")
	data = ''			#裁判データ
	title = ''			#主文
	riyu = ''			#事実及び理由
	frg = 0
	f.each_line{|line|
		line = line.delete("\s")		#文章中の空白消去
		p "before"+line
		line.gsub(/([a-zA-Z0-9０-９]|[!-:-~])/,"")
		p "after"+line
		begin
			if frg == 0
				if( /主文/ =~ line.chomp)
					title += line.chomp
					frg = 1
					next				#マッチしたらコンティニュー
				end
				data += line.chomp
			elsif frg == 1
				if(/(事実及び理由)|(理由１)|(理由第１)|(理由)|(事 実)/ =~ line.chomp)
					riyu += line.chomp
					frg = 2
					next				#マッチしたらコンティニュー
				end
				title += line.chomp
			elsif frg == 2
				riyu += line.chomp
			end
		rescue
			puts "error!!!!!!!!!!"
			frg = 3
		end
	}
	list = Hash.new
	list = {"id"=> "0000"+id.to_s,"data" => data, "title"=> title,"riyu"=> riyu}
}

