#coding:utf-8
from __future__ import print_function

from natto import MeCab
import re
import hanrei_db
import data

if __name__ == '__main__':
	path = '../../data/hanreiDB'
	nm = MeCab()
	db = hanrei_db.SQLite3(path)
# open the DB
	cur = db.open_db()
# read the data
	sql = "select id, riyuPart, summary from hanrei"
#	sql = u"select id, syubunPart, riyuPart from hanrei"
	rows = db.exe_to_db(cur, sql)
	for doc_id, riyuPart, summary in rows:
		# tot_cnt += 1
		if summary:	# except for "summary = None"
			summary = re.sub(r'(\s|　|\n|○)', "", summary)
			if summary != '':
				chara = 0
				# summ_cnt += 1		# \要約データカウント
				print("--------------")
				print("id:", doc_id)
				# riyuPart = riyuPart.replace('\n', '')	# 改行削除
				# sensp = sensplit.SenSplit(riyuPart)
				summary = data.sensp(summary)
				print("summary:", summary)
				print("要旨文数:", len(summary))
				chara = data.charaCount(summary)
				print("総要旨文数:", chara)
				# for sen in summary:
				# 	print(sen)
				# 	print(nm.parse(sen))

	# close the DB
	db.close_db()
	print("summ_cnt:", summ_cnt)
	print("tot_cnt:", tot_cnt)
