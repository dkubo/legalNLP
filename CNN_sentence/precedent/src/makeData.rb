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
	cnt=0
	sql="select id from hanrei"
	cursorID=db.executeSQL(sql)
	cursorID.each do |tuple_id|
#		print "\n----------------------------------------------\n"
		id_ = tuple_id[0]
		sql="select syubunPart,riyuPart,summary from hanrei where id='#{id_}'"
		cursor=db.executeSQL(sql)
		cursor.each do |tuple|
			syubun = tuple[0]
			riyu = tuple[1]
			text += syubun.delete("\n")
			text += riyu.delete("\n")
			summary=tuple[2]
			if summary != nil
				summary=summary.gsub(" ","")
			end
			if summary != nil
				summary=summary.gsub(" ","")
				if summary != ""
#					sp=SenSplit.new(text)
#					result=sp.split_period()
#					for res in result do
					if /#{summary}/ =~ text
						cnt+=1
						puts id_.to_s+","+summary.to_s
					end
				end
			end
#			text += syubun.delete("\n")
#			text += riyu.delete("\n")
#			sp=SenSplit.new(text)
#			result=sp.split_period()
#			puts result
		end
#		puts cnt
	end
	db.closeDB
end

main()

#/^((付録|目録|添付|別紙)/
