#coding: utf-8

import json
import sys
import copy
from collections import defaultdict

# DICT="../result/tsutsuji_dic_20161206.json"
ADDLIST="../result/candidate_edit.txt"
# RESULT_DIC="../result/tsutsuji_dic_20161215.json"


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

def writedic(toresult, jsondic):
	with open(toresult, "w") as f:
		json.dump(jsondic, f, ensure_ascii=False, indent=4, sort_keys=True, separators=(',', ': '))


def addDa(jsondic, mweid, mwe):
	if "から" == mwe:
		spemweid = "0282C"
	else:
		spemweid = "1201C"
	jsondic[spemweid] = copy.deepcopy(jsondic[mweid])

	jsondic[spemweid]["headword"] = "だ"+jsondic[spemweid]["headword"]
	jsondic[spemweid]["suw_lemma"] = ["だ"]+jsondic[spemweid]["suw_lemma"]
	jsondic[spemweid]["suw_lemma_yomi"] = ["ダ"]+jsondic[spemweid]["suw_lemma_yomi"]
	jsondic[spemweid]["global_pos"] = "接続詞型"
	jsondic[spemweid]["left"] = ["j0"]

	variationlist = jsondic[spemweid]["variation"]
	variation_lemmalist = jsondic[spemweid]["variation_lemma"]
	jsondic[spemweid]["variation"] = []
	jsondic[spemweid]["variation_lemma"] = []

	for variation in variationlist:
		jsondic[spemweid]["variation"].append("だ"+variation)
	for variation_lemma in variation_lemmalist:
		jsondic[spemweid]["variation_lemma"].append(["だ"]+variation_lemma)

	return jsondic

def makeentry(mweid, mwe, jsondic):
	if ("から" == mwe) or ("からといって" == mwe):	#この場合は、新しいmweidを付与して、エントリを作る
		jsondic = addDa(jsondic, mweid, mwe)
	else:
		if "Q" == mweid[-1]:	# Q→C
			newmweid = mweid[0:-1] + "C"
			jsondic[newmweid] = copy.deepcopy(jsondic[mweid])

			jsondic[newmweid]["global_pos"] = "接続詞型"
			jsondic[newmweid]["left"] = ["j0"]

		else:	# C→Q
			newmweid = mweid[0:-1] + "Q"
			jsondic[newmweid] = copy.deepcopy(jsondic[mweid])
			jsondic[mweid]["left"].append("j0")	# Cの制約にj0を加える
			jsondic[newmweid]["global_pos"] = "接続助詞型"

	return jsondic

def getpath():
	args = sys.argv
	return args[1], args[2]

def main():
	todict, toresult = getpath()
	jsondic = opendic(todict)
	v_cnt = 0
	for k,v in jsondic.items():
		v_cnt += len(v["variation"])
	print(v_cnt)

	addhash = openaddlist(ADDLIST)
	for mwe, addmweidlist in addhash.items():

		for mweid in addmweidlist:
			jsondic = makeentry(mweid, mwe, jsondic)

	v_cnt = 0
	for k,v in jsondic.items():
		v_cnt += len(v["variation"])
	print(v_cnt)

	# writedic(toresult, jsondic)

if __name__ == '__main__':
	main()
