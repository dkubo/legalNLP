#coding:utf-8
#条項ごとに分割して、アトミックファイル作成
require 'open-uri'
require 'nokogiri'

ROOT="/opt/e-gov/data/html"
OUT_INDEX="/opt/e-gov/data/index/"
OUT_JOBUN="/opt/e-gov/data/jobun/"
PATTERN="*.html"

#refファイル参照
Dir.chdir(ROOT)
Dir.glob(PATTERN) do |file|
	p '----------------------------'
	total = ''
	index = ''
	jobunAll = ''
	jobun_frg = 0
	f = open(file,"r")
	puts "法令名:"+file.chomp
	f.each_line{|l|
		if /<DIV class="item">/ =~ l
			jobun_frg = 1
		end
#		if /<!--/ =~ l.chomp
#			puts $&
#		end
		if /附則/ =~ l.chomp.lstrip.delete("\s\t　") and jobun_frg == 1
			break
		end
		total += l
	}
	html_doc = Nokogiri::HTML.parse(total)
	puts "-----------------------------------"
#	puts html_doc.title
	puts html_doc.inner_text
#	html_doc.xpath('//div[@class="item"]').each do |jobun|
#		jobunAll += jobun.text.chomp
#		jobunAll += "\n"
#	end
#	html_doc.xpath('//body//b').each do |honsoku|
#		index += honsoku.text.chomp
#		index += "\n"
#	end
	#index書き込み
#	File.open(OUT_INDEX+daimei+".txt","a") do |file|
#		file.write(index)
#	end
	#条文書き込み
#	File.open(OUT_JOBUN+daimei+".txt","a") do |file|
#		file.write(jobunAll)
#	end
end


