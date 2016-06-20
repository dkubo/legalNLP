#coding:utf-8

require './sqlite3.rb'
require './senSplit.rb'

"""
判決要旨がどれくらいの割合で存在するか確かめる

"""

DB_PATH="../data/hanreiDB"

def main()
	db=SQLight3.new(DB_PATH)
	text=""
	hash=Hash.new(0)
	cnt=0
	sum_cnt=0
	sql="select id from hanrei"
	cursorID=db.executeSQL(sql)
	cursorID.each do |tuple_id|
#		puts "---------------------------"
		id_ = tuple_id[0]
		sql="select riyuPart,summary,trialYear from hanrei where id=#{id_}"
		cursor=db.executeSQL(sql)
		cursor.each do |tuple|
			riyu = tuple[0]
			summary = tuple[1]
			trialYear = tuple[2]
			if summary != nil then
				summary=summary.delete(" 　").strip
				if "" != summary then
					sum_cnt+=1
					hash[trialYear]+=1
				end
			end
#			text += syubun.delete("\n")
#			text += riyu.delete("\n")
#			sp=SenSplit.new(text)
#			result=sp.split_period()
		end
		cnt+=1
		for k,v in hash do
			puts k+"："+v.to_s+"/"+cnt.to_s
		end
	end
	db.closeDB
end

main()

#/^((付録|目録|添付|別紙)/
