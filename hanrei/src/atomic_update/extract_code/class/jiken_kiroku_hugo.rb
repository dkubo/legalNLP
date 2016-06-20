#coding:utf-8
#事件記録符号からラベル情報取得
HUGO_PATH = '/home/daiki/デスクトップ/hanrei/hugo_clustering.csv'
class Jiken_Kiroku_Hugo
	def initialize()
		@hugo = ''
		@label = []
	end
	def get_hugo(accident_num)
		if /\(.*\)/ =~ accident_num
			@hugo = $&.delete('()（）')
		end
		return @hugo
	end
	def get_label(court_name)
		#事件記録符号分野参照
		if '行ナ' == @hugo
			if /(最高|知的財産)/ =~ court_name
				@label.push('行政再審事件')
			elsif /(高等|地方|家庭|簡易)/ =~ court_name
				@label.push('行政訴訟事件（1審）（旧）')
			end
		elsif '行セ' == @hugo
			if /(地方|家庭|簡易)/ =~ court_name
				@label.push('特別抗告提起事件')
			elsif /(高等)/ =~ court_name
				@label.push('行政特別抗告提起事件')
			end
		elsif 'わ' == @hugo
			if /(地方|家庭|簡易)/ =~ court_name
				@label.push('刑事上告事件（旧）')
				@label.push('刑事公判請求事件')
			elsif /(高等)/ =~ court_name
				@label.push('刑事上告事件（旧）')
			end
		else
			hugo_ref = open(HUGO_PATH,'r')
			hugo_ref.each_line{|h|
				hugo,label = h.delete("[]").split(".")
				if hugo == @hugo
					@label.push(label)
				end
			}
		end
		return @label
	end
end
