# -* coding: UTF-8 -*-
require 'kconv'

file = open('/opt/userdict_ja.txt','r')
file.each_line{|l|
	kazukana_frg = 0
	a,b,c,d = l.split(',')
	arr = a.split(//)
	for tmp in arr do		#一文字ずつtmpに代入
		if /[ァ-ヴ]/ =~ tmp
			kazukana_frg = 1
		else
			kazukana_frg = 0
		end
	end
	if 	kazukana_frg == 1
		puts a+","+b+","+c+",かずカナ名詞"
	else
		puts a+","+b+","+c+","+d
	end
}
