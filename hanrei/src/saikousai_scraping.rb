#coding:utf-8
#encoding:utf-8
require 'nokogiri'
require 'open-uri'
require 'fileutils'

#最高裁判例検索から、pdfリンクとそれに対応する裁判詳細データ取得
#昭和の境目：～昭和64年1月6日まで
#昭和の判例分：昭和22年9月15日～昭和63年12月27日
#平成の判例分：平成元年1月17日～最新まで
#scraping from:「裁判例情報」(http://www.courts.go.jp/app/hanrei_jp/search1)
#作成者：magnesium
#作成日：2014/9/7(月)


pdf_url = ''
data_url = ''
out_contents = ''
#期間指定で検索
KIKAN = '2'
#W_PATH = './pdf_url_list.txt'
W_PATH = ARGV[0]
#syousai_write path
W_PATH2 = ARGV[1]

#昭和→%E6%98%AD%E5%92%8C、平成→%E5%B9%B3%E6%88%90
#####################################
#				年号変換
#####################################
def convert_nengo(nengo)
	if nengo == '昭和' then
		nengo = '%E6%98%AD%E5%92%8C'
	elsif nengo == '平成' then
		nengo = '%E5%B9%B3%E6%88%90'
	else
		puts "error! ← 「昭和」もしくは「平成」を引数に！"
	end
	return nengo
end
#####################################
#				判決文取得期間指定
#####################################
def setting_date()
	start_nengo = convert_nengo(ARGV[2])
	start_year = ARGV[3]
	start_month = ARGV[4]
	start_day = ARGV[5]
	end_nengo = convert_nengo(ARGV[6])
	end_year = ARGV[7]
	end_month = ARGV[8]
	end_day = ARGV[9]
	return start_nengo,start_year,start_month,start_day,end_nengo,end_year,end_month,end_day
end
#####################################
#				合計ページ数
#####################################
def getPageNum(start_nengo,start_year,start_month,start_day,end_nengo,end_year,end_month,end_day)
	total_page_num=0
	root_url = 'http://www.courts.go.jp/app/hanrei_jp/list1?page=1&sort=1&filter[judgeDateMode]='+KIKAN+'&filter[judgeGengoFrom]='+start_nengo+'&filter[judgeYearFrom]='+start_year+'&filter[judgeMonthFrom]='+start_month+'&filter[judgeDayFrom]='+start_day+'&filter[judgeGengoTo]='+end_nengo+'&filter[judgeYearTo]='+end_year+'&filter[judgeMonthTo]='+end_month+'&filter[judgeDayTo]='+end_day
	root_page = Nokogiri::HTML( open( root_url ).read )
	#件数取得
	root_page.xpath("//div[@class='s_title']//h4[@class='s_title_l']" ).each{|l|
		if /全判例統合[0-9].+件中/ =~ l.inner_text then
			doc_num = $&.delete("全判例統合件中").to_i
			if (doc_num%10)==0 then
				total_page_num=doc_num/10
			else
				total_page_num=(doc_num/10)+1
			end
		end
	}
	return total_page_num
end
#####################################
#				詳細データ出力先分類
#####################################
def classify_dir(fname,root_path)
	dir_path=""
	out_path=""
	if fname.length == 5 then
		dir_path=root_path+fname[0]+"/"+fname[1]+"/"+fname[2]+"/"
	elsif fname.length > 5 then
		dir_path=root_path+fname[0..(fname.length-5).to_i]+"/"+fname[(fname.length-4).to_i]+"/"+fname[(fname.length-3).to_i]+"/"
	elsif fname.length == 4 then
		dir_path=root_path+"0/"+fname[0]+"/"+fname[1]+"/"
	elsif fname.length == 3 then
		dir_path=root_path+"0/0/"+fname[0]+"/"		
	else
		dir_path=root_path+"0/0/0/"		
	end	
	FileUtils.mkdir_p(dir_path)
	out_path=dir_path+fname+".csv"
	return out_path
end
#####################################################################
#								main
#####################################################################
start_nengo,start_year,start_month,start_day,end_nengo,end_year,end_month,end_day = setting_date()
#####################################################################
#ページを指定しないように改善
#####################################################################
total_page_num=getPageNum(start_nengo,start_year,start_month,start_day,end_nengo,end_year,end_month,end_day)
for page_num in 1..total_page_num do
	root_url = 'http://www.courts.go.jp/app/hanrei_jp/list1?page='+page_num.to_s+'&sort=1&filter[judgeDateMode]='+KIKAN+'&filter[judgeGengoFrom]='+start_nengo+'&filter[judgeYearFrom]='+start_year+'&filter[judgeMonthFrom]='+start_month+'&filter[judgeDayFrom]='+start_day+'&filter[judgeGengoTo]='+end_nengo+'&filter[judgeYearTo]='+end_year+'&filter[judgeMonthTo]='+end_month+'&filter[judgeDayTo]='+end_day
	root_page = Nokogiri::HTML( open( root_url ).read )
	#divタグのうちid=listのタグのa属性をサーチ
	root_page.xpath("//div[@id='list']//a" ).each{|l|
		begin
			list_part_url = l["href"]
		rescue  => err
			print err, "\n"
		end
		#ファイル名出力
		if /.pdf/ =~ list_part_url then
			source_url = list_part_url
			pdf_url = 'http://www.courts.go.jp'+ source_url
			#pdf_urlリストファイル書き込み
			File.open(W_PATH,"a+"){|line|
				line.write pdf_url
				line.write "\n"
			}
		elsif /\?id=/ =~ list_part_url then
			data_url = 'http://www.courts.go.jp'+ list_part_url
			#ファイル出力パス
			fname=$'
			last_page = Nokogiri::HTML(open(data_url).read)
			out_contents = ''
			#divタグのうちclassがdlistのタグをサーチ
			last_page.xpath("//div[@class='dlist']").each{|d_list|
				#全html
				out_contents += d_list.inner_html
			}
			out_path=classify_dir(fname,W_PATH2)
			puts out_path
			#出力ファイルオープン
			File.open(out_path,"a+"){|line|
				line.write out_contents
				line.write "\n"
			}	
		end
	}
	sleep 1
	puts "page #{page_num} done!!"
end

