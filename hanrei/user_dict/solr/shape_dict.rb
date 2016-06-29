#coding:utf-8

#目的：houritu_dict.csvをSolrのユーザ辞書の形に変換する
#作成者：magnesium
#作成日：2014/7/31

SOURCE_FILE = "./houritu_dict.csv"
OUT_FILE = "./userdict_houritu_dict.csv"

#ひらがな　→　カタカナ
class String
	def to_kana
    self.tr('ぁ-ん','ァ-ン')		#置換
  end
end

f = open(SOURCE_FILE,"r")
f.each_line{|l|
	array = l.chomp.split("\s")
	#if !(/名詞/ =~ array[2])
	#	p array[0]
	#end
	#ファイル出力
	File.open(OUT_FILE,"a+") do |line|
		#line.write(array[1]+","+array[1]+","+array[0].to_kana.to_s+",カスタム名詞"+"\n")	#全て名詞サ変
		line.write(array[1]+","+array[1]+","+array[0].to_kana.to_s+","+array[2]+"\n")	#
	end
}


