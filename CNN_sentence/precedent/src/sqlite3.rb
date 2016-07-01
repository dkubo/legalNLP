#coding:utf-8
require 'sqlite3'

class SQLight3
	def initialize(dbname)
		@dbname=dbname
		@db = SQLite3::Database.new(@dbname)
	end
	#カラム、テーブルを指定してデータを挿入
	def insertData(table,column,value)
		sql="insert into #{table}(#{column}) values(#{value});"
		@db.execute(sql)
	end
	#カラム、テーブルを指定してデータを取得
	def executeSQL(sql)
		return @db.execute(sql)
	end
	def closeDB()
		@db.close
	end
end
