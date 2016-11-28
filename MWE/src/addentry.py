#coding: utf-8

import json

DICT="../result/tsutsuji_dic_20161121.json"
ADDLIST="../result/candidate_edit.txt"

def opendic(path):
	with open(path, 'r') as f:
		jsondata = json.load(f)
	return jsondata

def openaddlist(path):
	with open(path, 'r') as f:
		for line in f:
			mwe, mweidlist = line.rstrip().split("\t")
			print(mwe, mweidlist)


def main():
	jsondic = opendic(DICT)
	# print(jsondic)

	openaddlist(ADDLIST)

if __name__ == '__main__':
	main()