#coding: utf-8

import json
from collections import defaultdict

DIC="../result/tsutsuji_dic_20161121.json"

def main():
	with open(DIC, 'r') as f:
		jsondata = json.load(f)

	cqlist = defaultdict(list)
	for k, v in jsondata.items():
		if v["global_pos"] in ["接続詞型" , "接続助詞型"]:
			cqlist[v["headword"]].append(k)

	for k, v in cqlist.items():
		pos = []
		# k = k.encode('utf-8')
		for mweid in v:
			pos.append(mweid[-1])
		if ("Q" in pos) and ("C" in pos):
			next
		else:
			# if (len(k) >= 2):
				print(k, v, sep=",")

if __name__ == '__main__':
	main()