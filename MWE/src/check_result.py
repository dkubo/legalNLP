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

	# print(needed_meaninglist)
	# print(len(needed_meaninglist))
	return outdata

def sortMWE(outdata):
	outdata.sort(key=lambda x:x[5])	# mweでsort
	return outdata

def groupingMWE(outdata):
	newoutdata, grouplist = [], []
	premwe,curmwe = "", ""

	for i, token in enumerate(outdata):
		curmwe = token[5]
		if i == 0:
			premwe = token[5]

		if premwe == curmwe:
			grouplist.append(token)
		else:
			newoutdata.append(grouplist)
			grouplist = []
			grouplist.append(token)

		premwe = copy.deepcopy(curmwe)
	newoutdata.append(grouplist)
	return newoutdata

def dictShape(posmean):
	outstring, num = "", 1
	for mweid, meanings in posmean.items():
		posid = mweid[-3]	# mweid: str
		meanings = re.sub(r'(\[|\'|\'|\]|\s)',"", meanings[0]).split(",")
		for meaning in meanings:
			outstring += str(num)+"=>"+posid+":"+meaning+","
			num += 1
	return outstring[0:-1]


def collectMWEID(outdata):
	newoutdata = []
	for group in outdata:
		samesentspan = defaultdict(list)
		for token in group:
			samesentspan[(token[1],token[2],token[3])].append(token)	# sentid, begin, end

		for key, tokens in samesentspan.items():
			posmean = defaultdict(list)
			newtoken, mweids = [], []
			for token in tokens:
				if len(token) == 1:
					newoutdata.append(token[1:])
					break
				else:
					newtoken = token[1:-1]	# except for meanings
					mweids.append(token[0])
					posmean[token[0]].append(token[-1])
			# newtoken.insert(0, ','.join(mweids))
			posmean = dictShape(posmean)
			newtoken.append(posmean)
			newoutdata.append(newtoken)

	return newoutdata

def main():
	# output, matchspan, meaninglist = data(fpath, frg=1)
	# countMeaning(list(set(meaninglist)))

	fpath1 = "../result/dev_matced_1202.csv"
	outpath1 = "../result/dev_matced_1202_buf.tsv"

	output, matchspan, meaninglist = data(fpath1, frg=0)
	outdata = checkSamespan(output, matchspan)
	writeCSV(outpath1, outdata)


	output, matchspan, meaninglist = data(outpath1, frg=1)
	outdata = removeIreko(output, matchspan)
	outdata = sortMWE(outdata)
	outdata = groupingMWE(outdata)
	outdata = collectMWEID(outdata)

	outpath2 = "../result/dev_matced_1202_rmoneword.tsv"
	writeCSV(outpath2, outdata)





if __name__ == '__main__':
	main()
