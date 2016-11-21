#coding:utf-8
from __future__ import print_function

from natto import MeCab
import re
import hanrei_db
import data


def n_gram(uni, n):
	return [uni[k:k+n] for k in range(len(uni)-n+1)]


def getngram(sentences):
	nlist = []
	for sentence in sentences:
		nlist.append(n_gram(sentence, 2))
	return nlist

if __name__ == '__main__':
	path = '../../data/hanreiDB'
	nm = MeCab()
	db = hanrei_db.SQLite3(path)

	# open the DB
	cur = db.open_db()

	# read the data
	sql = "select id, riyuPart, summary from hanrei"
	rows = db.exe_to_db(cur, sql)
	for doc_id, riyuPart, summary in rows:
		# 要旨が存在する判例のみ解析対象とする
		if summary and riyuPart:	# except for "summary = None and riyuPart = None"
			summary = re.sub(r'(\s|　|\n|○)', "", summary)
			riyuPart = re.sub(r'(\s|　|\n|○)', "", riyuPart)
			if summary != '' and riyuPart != '':
				print("--------------")
				print("id:", doc_id)
				summary = data.sensp(summary)
				riyuPart = data.sensp(riyuPart)
				sum_nlist = getngram(summary)
				riyu_nlist = getngram(riyuPart)
				print(sum_nlist)
	# close the DB
	db.close_db()
