#coding:utf-8

#親の裁判所を登録ファイルに記載
class Parent_Court
	def initialize()
		@parent_court = ''
	end
	def classify(court_name)
		if /簡易裁判所/ =~ court_name
			@parent_court = '簡易裁判所'
		elsif /家庭裁判所/ =~ court_name
			@parent_court = '家庭裁判所'
		elsif /地方裁判所/ =~ court_name
			@parent_court = '地方裁判所'			
		elsif /高等裁判所/ =~ court_name
			@parent_court = '高等裁判所'
		elsif /最高裁判所/ =~ court_name
			@parent_court = '最高裁判所'
		end
		return @parent_court
	end	
end
