#coding: utf-8

import json
from collections import defaultdict

DICT="../result/tsutsuji_dic_20161121.json"
ADDLIST="../result/candidate_edit.txt"

def opendic(path):
	with open(path, 'r') as f:
		jsondata = json.load(f)
	return jsondata

def openaddlist(path):
	addhash = {}
	# addhash = defaultdict(list)
	with open(path, 'r') as f:
		for line in f:
			mwe, mweidlist = line.rstrip().split("\t")
			addhash[mwe] = mweidlist.split(",")
	return addhash

def main():
	jsondic = opendic(DICT)
	addhash = openaddlist(ADDLIST)
	for mwe, mweidlist in addhash.items():
		for mweid in mweidlist:
			print(jsondic[mweid])

if __name__ == '__main__':
	main()