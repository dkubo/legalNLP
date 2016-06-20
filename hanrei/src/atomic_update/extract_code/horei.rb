#coding:ascii-8bit
#法律の条文を条項ごとに分類して、抽出
require 'nokogiri'

ROOT='/home/daiki/デスクトップ/intron/scraping/e-gov/data/html/'
PATTERN='*.html'

Dir.chdir(ROOT)
Dir.glob(PATTERN) do |file|
	total = ''
	puts '----------------------'
	name = file.split('/')[-1].delete('.html')
	p name
	s_file = open(file,'r')
	s_file.each_line{|l|
		total += l
	}
	p total.force_encoding("utf-8")
end

