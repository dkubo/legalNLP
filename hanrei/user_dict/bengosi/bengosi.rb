#coding:utf-8
#弁護士ドットコムから法律用語スクレイピングコード

require 'hpricot'
require 'kconv'
require 'open-uri'

#.times do |page|
page = 1
while page <= 7300 do
	begin
		url = "http://www.bengo4.com/saiban/d_"+"#{page}"	#弁護士ドットコム
		doc = Hpricot(open(url).read)
		tmp = doc.search('div.related-info-case-full-text')
		yogo = tmp.search('h1').inner_html
		other,yomi = tmp.search('span').inner_html.split('：')
		yomi = yomi.tr('ぁ-ん','ァ-ン')		#ひらがな→カタカナ
		puts "#{yogo},#{yogo},#{yomi},名詞サ変"
		page += 1
		sleep(rand(5)+1)		#wait
	rescue
		page += 1
		sleep(rand(5)+1)		#wait
		next
	end
end
