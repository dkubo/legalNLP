#coding: utf-8

from collections import defaultdict, Counter
import csv
import copy
import re

# マッチスパンが入れ子or 包含になっているものを確認
# マッチMWEの種類数カウント

def data(fpath, frg):
	meaninglist, matchspan, output = [], defaultdict(list), defaultdict(list)

	with open(fpath, "r") as f:
		for line in f:
			if frg == 0:
				mweid, sentid, b, e, pre, mwe, post, meaning = line.rstrip().split(",")
				b, e, mweid, meaning = int(b), int(e), [mweid], [meaning]
				output[(sentid, (b,e), mweid[0][-1])].append([mweid, sentid, b, e, pre, mwe, post, meaning])
				matchspan[sentid, mweid[0][-1]].append((b,e))
				meaninglist.append(meaning)
			else:
				mweid, sentid, b, e, pre, mwe, post, meaning = line.rstrip().split("\t")
				b, e, mweid, meaning = int(b), int(e), mweid, meaning
				output[(sentid, (b,e), mweid)].append([mweid, sentid, b, e, pre, mwe, post, meaning])
				matchspan[sentid, mweid].append((b,e))
				meaninglist.append(meaning)
	return output, matchspan, meaninglist


def writeCSV(MOD_RESULT, outdata):
	# '\t'.join([str(i) for i in outdata])
	with open(MOD_RESULT, 'w') as f:
		writer = csv.writer(f, lineterminator='\n', delimiter = '\t')
		writer.writerows(outdata)

def countMeaning(meaninglist):
	meaninglist = sorted(set(meaninglist), key=meaninglist.index)
	print(meaninglist)
	print(len(meaninglist))		# 77


def push(ireko, begin, end):
	if not end in ireko[begin]:
		ireko[begin].append(end)
	return ireko

def recur(value, ireko):
	for i, (begin, end) in enumerate(value):
		if i == 0:
			beginobj, endobj = begin, end
		else:
			if (beginobj == begin):
				push(ireko, beginobj, end)
				push(ireko, beginobj, endobj)

	return ireko

def irekoCheck(value, output):
	ireko = defaultdict(list)
	other = copy.deepcopy(value)
	spannum = len(value)

	for cnt in range(0, spannum):
		ireko = recur(value, ireko)
		value.pop(0)

	spans = getlongerspan(ireko, other)

	return spans

def getlongerspan(ireko, other):
	spans = []

	for startidx, endidxlist in ireko.items():
		endidxlist.sort()
		for endidx in endidxlist:
			other.remove((startidx, endidx))

		# 長いものを採用
		span = (startidx, endidxlist[-1])
		spans.append(span)
	
	if other != []:
		spans += other

	return spans

def removeIreko(output, matchspan):
	spans, outdata = [], []

	for (sentid, mweid), v in matchspan.items():
		if len(v) >= 2:		# 同一の文内で、複数マッチしている場合⇒入れ子等になっている可能性がある
			spans = irekoCheck(v, output)

			for span in spans:
				outdata += output[(sentid, span, mweid)]

		else:
			outdata += output[(sentid, v[0], mweid)]

	# print(outdata)	#
	# print(len(outdata))	#
	return outdata

def extractSamespan(v):
	return [key for key,val in Counter(v).items() if val > 1]

def	collectMeaning(sentid, posid, samespans, output2, outdata, needed_meaninglist):
	for samespan in samespans:
		mweids, meanings = [], []		# スパン,品詞,意味は全く同じで、mweidだけ違う場合に対象
		for mweid, sentid, b, e, pre, mwe, post, meaning in output2[(sentid, samespan, posid)]:
			if not meaning[0] in meanings:
				meanings += meaning
			if not mweid in mweids:
				mweids += mweid

			if not meaning[0] in needed_meaninglist:
				needed_meaninglist += meaning

		outdata.append([mweids, sentid, b, e, pre, mwe, post, meanings])
	return needed_meaninglist

def checkSamespan(output2, matchspan2):
	outdata, needed_meaninglist = [], []	# インストラクションが必要な意味カテゴリのリスト用

	for k, v in matchspan2.items():
		sentid, posid = k
		samespans = extractSamespan(v)
		v = list(set(v) - set(samespans))
		if samespans != []:		# スパンに重複がある場合
			for span in v:
				outdata += output2[(sentid, span, posid)]
			needed_meaninglist = collectMeaning(sentid, posid, samespans, output2, outdata, needed_meaninglist)
		else:
			for span in v:
				outdata += output2[(sentid, span, posid)]

	print(needed_meaninglist)
	print(len(needed_meaninglist))
	return outdata

def main():
	fpath1 = "../result/matced_mwe_1201.csv"
	outpath1 = "../result/matced_mwe_1201_mod.csv"

	output, matchspan, meaninglist = data(fpath1, frg=0)
	outdata = checkSamespan(output, matchspan)
	writeCSV(outpath1, outdata)


	outpath2 = "../result/matced_mwe_1201_rmoneword.csv"
	output, matchspan, meaninglist = data(outpath1, frg=1)
	outdata = removeIreko(output, matchspan)
	writeCSV(outpath2, outdata)

	# fpath = "../result/matced_mwe_1130_mod.csv"
	# output, matchspan, meaninglist = data(fpath, frg=1)
	# countMeaning(list(set(meaninglist)))


if __name__ == '__main__':
	main()
