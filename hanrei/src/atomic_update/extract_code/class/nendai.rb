#coding:utf-8
#年代を大きく分けてメタ情報を生成するコード

require 'date'

class Nendai
	def initialize(date)
		@date = date
	end
	def big_sort
		if /昭和(22|23|24)年/ =~ @date
			@parent_date = '1940年代'
		elsif /昭和(2(5|6|7|8|9)|3(0|1|2|3|4))年/ =~ @date
			@parent_date = '1950年代'
		elsif /昭和(3(5|6|7|8|9)|4(0|1|2|3|4))年/ =~ @date
			@parent_date = '1960年代'
		elsif /昭和(4(5|6|7|8|9)|5(0|1|2|3|4))年/ =~ @date
			@parent_date = '1970年代'
		elsif /(昭和(5(5|6|7|8|9)|6(0|1|2|3|4))年)|(平成元年)/ =~ @date
			@parent_date = '1980年代'
		elsif /平成(2|3|4|5|6|7|8|9|10|11)年/ =~ @date
			@parent_date = '1990年代'
		elsif /平成(1(2|3|4|5|6|7|8|9)|2(0|1))年/ =~ @date
			@parent_date = '2000年代'
		elsif /平成(2(2|3|4|5|6|7|8|9)|3(0|1))年/ =~ @date
			@parent_date = '2010年代'
		end
		return @parent_date
	end
	#input:2001or2001年→output:2000年代
	def childToParent
		@date = @date.delete("年")
		case @date[0,3]
		when '194'
			parent_year = '1940年代'
		when '195'
			parent_year = '1950年代'
		when '196'
			parent_year = '1960年代'
		when '197'
			parent_year = '1970年代'
		when '198'
			parent_year = '1980年代'
		when '199'
			parent_year = '1990年代'
		when '200'
			parent_year = '2000年代'
		when '201'
			parent_year = '2010年代'
		when '202'
			parent_year = '2020年代'
		end
		return parent_year

	end
	#年代小分類(西暦に変換するだけ)
	def small_sort
		if /元年/ =~ @date
			@date = @date.gsub(/元/,'1')			#平成元年の時、平成1年に変換
		end
		@date = @date.gsub(/(年|月)/,'.')
		@date = @date.gsub(/平成/,'H')
		@date = @date.gsub(/昭和/,'S')
		@date = @date.delete('日')
		@child_date = Date.parse(@date)
		return @child_date.to_s.slice(0,4)+'年'
	end
end
