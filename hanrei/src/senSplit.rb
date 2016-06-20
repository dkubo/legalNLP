#coding:utf-8
require 'sqlite3'

class SenSplit
	def initialize(text)
		@text=text
	end
	def split_period()
		res = []
		sensp = []
		merge=""
		open_cnt=0
		close_cnt=0
		res = @text.split("。")

		for part in res do
			open_cnt+=part.count("(（「")
			close_cnt+=part.count(")）」")
			if (open_cnt > close_cnt) then
				merge+=part+"。"
			else
				merge+=part
				sensp.push(merge)
				merge=""
			end
		end
		return sensp
	end
end

