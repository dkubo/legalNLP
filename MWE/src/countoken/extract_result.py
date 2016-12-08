#coding: utf-8

import json
import re
import csv
from collections import defaultdict

def getMWEID(todict):
	mweidlist = []
	with open(todict, 'r') as f:
		jsonData = json.load(f)

	for mweid, v in jsonData.items():
		# print("--------------------------")
		if len(v["suw_lemma"]) >= 2:
			# print(mweid, v["headword"])
			for pos in v["suw_lemma_pos"]:
				pos = pos.split("-")
				# print(pos)
				if pos[0] in ["名詞", "動詞", "形容詞"]:
					mweidlist.append(mweid)
					break
	return mweidlist

def shape(matchedList):
	poslist, outstring = defaultdict(list), ""
	for i in matchedList:
		if i[-1] in ["P", "T", "W", "N"]:
			poslist["P"].append(i)
		elif i[-1] in ["Q", "C"]:
			poslist["C"].append(i)
		else:
			poslist[i[-1]].append(i)

	for num, (pos, ids) in enumerate(poslist.items()):
		outstring += str(num+1) + "=>" + pos + ","

	outstring += "0=>その他"
	return outstring

def extract(mweidlist, resultpath):
	result = []
	pattern = r"\d{4}[A-Z]{1}"
	with open(resultpath, 'r') as f:
		for line in f:
			line = line.split("\t")
			m_mweids = re.sub("\[|\]|'|\s","",line[0]).split(",")
			matchedList = re.findall(pattern, line[-1])
			line[-1] = shape(matchedList)
			for m_mweid in m_mweids:
				if m_mweid in mweidlist:
					result.append(line[1:])
					break
				else:
					continue

	return result

def writeCSV(path, outdata):
	with open(path, 'w') as f:
		writer = csv.writer(f, lineterminator='\n', delimiter = '\t')
		writer.writerows(outdata)

def main():
	# todict = "../result/tsutsuji_dic_20161128.json"
	# resultpath = "../result/dev_matced_1202_rmoneword_naibu.tsv"
	todict = "../../result/tsutsuji_dic_20161206.json"
	resultpath = "../../result/ud/matced_dev_1206_rmoneword_naibu.tsv"
	outpath = "./ud_annotation_dev_1208.tsv"

	mweidlist = getMWEID(todict)
	result = extract(mweidlist, resultpath)
	writeCSV(outpath, result)


if __name__ == '__main__':
	main()

