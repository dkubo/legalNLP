#coding:utf-8
#Solr出力結果を日付順でソートする用に数値型で日付フィールド作成
#例:平成25年4月14日→20150414

class Convert_Date
	require 'date'
	def initialize()
		@int_date = ''
	end
	def extract_year(date_value)
		child_date = ''
		year = ''
		month = ''
		date = ''
		if /元年/ =~ date_value
			date_value = date_value.gsub(/元/,'1')			#平成元年の時、平成1年に変換
		end
		date_value = date_value.gsub(/(年|月)/,'.')
		date_value = date_value.gsub(/平成/,'H')
		date_value = date_value.gsub(/昭和/,'S')
		date_value = date_value.delete('日')
		child_date = Date.parse(date_value)
		year = child_date.to_s.slice(0,4)
		tmp = date_value.split(".")
		month = tmp[1]
		date = tmp[2]
		if month.length == 1
			month = "0"+month
		end
		if date.length == 1
			date = "0" + date
		end
		@int_date = year+month+date
		return @int_date
	end
end
