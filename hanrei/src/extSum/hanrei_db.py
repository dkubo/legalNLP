#coding:utf-8
from __future__ import print_function
import sqlite3

class SQLite3:
	def __init__(self, path):
		self.path = path
		
	def open_db(self):
		# connect to the DB
		con = sqlite3.connect(self.path)
		self.con = con

		# make a cursor
		return con.cursor()

	def close_db(self):
		self.con.close()

	def exe_to_db(self, cur, sql):
		return cur.execute(sql)


if __name__ == '__main__':
	# path = '../../data/hanreiDB'
	db = SQLite3(path) 

	# open the DB
	cur = db.open_db()

	# read the data
	sql = u"select id, syubunPart from hanrei"
#	sql = u"select id, syubunPart, riyuPart from hanrei"
	rows = db.exe_to_db(cur, sql)
	for doc_id, syubunPart in rows:
		print(doc_id, syubunPart)
	
# close the DB
	db.close_db()
	
	
