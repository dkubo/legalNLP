#coding:utf-8
#審級を判断して分類するコード

class Sinkyu
	def initialize(court_name,gensin_court_name)
		@court_name = court_name
		@gensin_court_name = gensin_court_name
	end
	def sort
		#原審裁判所名がない場合(注意:ただデータが無く、原審が不明な場合もこっちの分岐に入ってしまう)
		if @gensin_court_name == '' then
			if /(簡易|家庭|地方|高等)裁判所/ =~ @court_name
				@sinkyu = '第一審'
			#最高裁は原審のデータがなくても必ず第三審
			elsif /最高裁判所/ =~ @court_name
				@sinkyu = '第三審'
			end
		#原審が簡易裁判所の場合
		elsif /簡易裁判所/ =~ @gensin_court_name
			if /地方裁判所/ =~ @court_name
				@sinkyu = '第二審'
			elsif /高等裁判所/ =~ @court_name
				@sinkyu = '第二審'
			end
		#原審が地方裁判所の場合
		elsif /地方裁判所/ =~ @gensin_court_name
			######原審裁判所名だけでは判断不能(原審とは一つ前の裁判のこと(第一審のことではない))######
			#簡易→地方→高等の場合がある
			if /高等裁判所/ =~ @court_name
				@sinkyu = '第二審or第三審'
			end
		#原審が家庭裁判所の場合
		elsif /家庭裁判所/ =~ @gensin_court_name
			if /高等裁判所/ =~ @court_name
				@sinkyu = '第二審'
			end
		#原審が高等裁判所の場合
		elsif /高等裁判所/ =~ @gensin_court_name
			if /最高裁判所/ =~ @court_name
				@sinkyu = '第三審'
			end
		end
		return @sinkyu
	end
end


