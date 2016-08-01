#coding:utf-8

import sqlite3

def open_db(path):
	return sqlite3.connect("data.db")

def exe_to_db(cur, sql):
	return cur.execute(sql)

if __name__ == '__main__':
	DB_PATH = '../data/hanreiDB'
	
	# open the DB
	con = open_db(DB_PATH)

	# make a cursor
	cur = con.cursor()
	
	# read the data
	sql = u"select id, syubunPart, riyuPart from hanrei"
	rows = exe_to_db(cur, sql)
	
	# close the DB
	con.close()
	
