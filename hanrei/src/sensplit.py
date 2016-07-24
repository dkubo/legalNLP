#coding:utf-8
import sqlite3
import re

class SenSplit:
	def __init__(self, text):
		self.text = text

	def __call__(self):
		res = []
		sensp = []
		merge = ""
		open_cnt = 0
		close_cnt = 0
		res = self.text.split("。")
		pt_o = re.compile(r"(\(|（|「)")
		pt_c = re.compile(r"(\)|）|」)")

		for part in res:
			open_cnt += len(pt_o.findall(part))
			close_cnt += len(pt_c.findall(part))
			if open_cnt > close_cnt:
				merge += part + "。"
			else:
				merge += part
				sensp.append(merge)
				merge = ""
		return sensp

if __name__ == '__main__':
	sensp = SenSplit("ぷよぷよしたいな。でも、（たぶん。）テトリスでもいいかも！んんー。")
	result = sensp()
	for i in result:
		print i
	
