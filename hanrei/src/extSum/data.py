#coding:utf-8
from __future__ import print_function
import re

def sensp(text):
	res = []
	sensp = []
	merge = ""
	open_cnt = 0
	close_cnt = 0
	res = text.split(u"。")
	pt_o = re.compile(r'\(|（|「')
	pt_c = re.compile(r'\)|）|」')

	for part in res:
		open_cnt += len(re.findall(pt_o, part))
		close_cnt += len(re.findall(pt_c, part))
		# print part, open_cnt, close_cnt
		if open_cnt > close_cnt:
			merge += part + u"。"
		else:
			merge += part
			sensp.append(merge)
			merge = ""

	while(True):
		try:
			sensp.remove("")
		except:
			break
	return sensp


def charaCount(summary):
	chara = 0
	for summ in summary:
		chara += len(summ)
	return chara