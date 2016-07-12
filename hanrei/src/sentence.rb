#coding:utf-8

require './sqlite3.rb'
require './senSplit.rb'
"""
判決文の文分割を行う
・目次の情報も参照する必要あり
"""

DB_PATH="../data/hanreiDB"

def main()
	db=SQLight3.new(DB_PATH)
	text=""
	result=[]
	sql="select id from hanrei"
	cursorID=db.executeSQL(sql)
	cursorID.each do |tuple_id|
		puts tuple_id[0]
#		sql="select syubunPart,riyuPart from hanrei where id='3159'"
#		cursor=db.executeSQL(sql)
#		cursor.each do |tuple|
#			syubun = tuple[0]
#			riyu = tuple[1]
#			text += syubun.delete("\n")
#			text += riyu.delete("\n")
#			sp=SenSplit.new(text)
#			result=sp.split_period()
#			puts result
#		end
	end
	db.closeDB
end

main()

#/^((付録|目録|添付|別紙)/
