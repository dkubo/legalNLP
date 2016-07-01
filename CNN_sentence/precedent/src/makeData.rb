#coding:utf-8

require './sqlite3.rb'
require './senSplit.rb'
"""
・要旨(ratio decidendi)とそれ以外のデータを作る
・this data for sentence classfication

"""

DB_PATH="/home/daiki/デスクトップ/naist/legal/hanrei/data/hanreiDB"

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
