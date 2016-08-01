#coding:utf-8

import re
import hanrei_db
import sensplit

if __name__ == '__main__':
	path = '../data/hanreiDB'
	db = hanrei_db.SQLite3(path)
# open the DB
	cur = db.open_db()
# read the data
	sql = "select id, syubunPart from hanrei"
#	sql = u"select id, syubunPart, riyuPart from hanrei"
	rows = db.exe_to_db(cur, sql)
	for doc_id, syubunPart in rows:
		print "--------------"
		print "id:", doc_id
		syubunPart = syubunPart.replace('\n', '')		# 改行削除
		sensp = sensplit.SenSplit(syubunPart)
		result = sensp()
		for sen in result:
			print sen
# close the DB
	db.close_db()
