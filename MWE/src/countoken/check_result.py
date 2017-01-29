#coding: utf-8

from collections import defaultdict, Counter
import csv
import copy
import re
import sys

# マッチスパンが入れ子or 包含になっているものを確認
# マッチMWEの種類数カウント

##########################
# 品詞∧スパンでデータ抽出
##########################
def data(fpath):
	matchspan, output = defaultdict(list), defaultdict(list)
	with open(fpath, "r") as f:
		for line in f:
			mweid, sentid, b, e, pre, mwe, post = line.rstrip().split(",")
			b, e = int(b), int(e)
			output[(sentid, (b,e), mweid[-1])].append([mweid, sentid, str(b), str(e), pre, mwe, post])
			if not (b,e) in matchspan[sentid, mweid[-1]]:	# 重複防止
				matchspan[sentid, mweid[-1]].append((b,e))
	return output, matchspan

#############################################################
# マッチスパンから重複してるスパンだけを抽出
#############################################################
# def extractSamespan(v):
# 	return [key for key,val in Counter(v).items() if val > 1]

def push(ireko, begin, end):
	if not end in ireko[begin]:
		ireko[begin].append(end)
	return ireko

def sortMWE(outdata):
	outdata.sort(key=lambda x:x[5])	# mweでsort
	return outdata

def dictShape(posmean):
	outstring, num = "", 1
	idlist = ""

	for mweid, _ in posmean.items():
		idlist += re.sub("\[|\]|\'","", mweid) + ","
	# for mweid, meanings in posmean.items():
		posid = mweid[-3]	# mweid: str
		# meanings = re.sub(r'(\[|\'|\'|\]|\s)',"", meanings[0]).split(",")
		# for meaning in meanings:
			# outstring += str(num)+"=>"+posid+":"+meaning+","
		outstring += str(num)+"=>"+posid+","
		num += 1
	return outstring+"0=>その他", idlist[0:-1]


###########################
# 長いスパンを採用
###########################
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

###########################
# 入れ子抽出
###########################
def recur(value, ireko):
	for i, (begin, end) in enumerate(value):
		if i == 0:
			beginobj, endobj = begin, end
		else:
			if (beginobj == begin):
				push(ireko, beginobj, end)
				push(ireko, beginobj, endobj)
	return ireko

###########################
# マッチスパン内の入れ子チェック
###########################
def irekoCheck(v, srcdata):
	ireko = defaultdict(list)
	other = copy.deepcopy(v)
	spannum = len(v)
	for cnt in range(0, spannum):
		ireko = recur(v, ireko)
		v.pop(0)
	spans = getlongerspan(ireko, other)
	return spans	# 入れ子除去済みスパン

##################################
# マッチスパン内の入れ子除去(長いスパンを採用)
##################################
def removeIreko(srcdata, matchspan):
	spans, outdata = [], defaultdict(list)
	for (sentid, posid), v in matchspan.items():
		# 同一の文内で、複数マッチしている場合⇒>入れ子等になっている可能性がある
		if len(v) >= 2:
			spans = irekoCheck(v, srcdata)	# 入れ子除去済みスパン
			for span in spans:
				outdata[(sentid, span, posid)] += srcdata[(sentid, span, posid)]
		else:
			outdata[(sentid, v[0], posid)] += srcdata[(sentid, v[0], posid)]
	return outdata

################
#	品詞集約
################
def collectPOS(outdata):
	collected = defaultdict(list)
	for (sentid, span, posid), tokens in outdata.items():
		for token in tokens:
			mweid = token[0]
			if len(collected[sentid, span]) == 0:
				collected[sentid, span] += [[mweid]] + token[1:]
			else:
				collected[sentid, span][0].append(mweid)
	return collected

#########################
#	出力整形
#########################
def forAnnotate(outdata):
	output = []
	for (sentid, span), token in outdata.items():
		mweids = ",".join(token[0])
		output.append(["\t".join(token[1:]) + "\t" + mweids])
	return output

#########################
#	tsv 出力
#########################
def writeTSV(path, output, last=0):
	with open(path, 'w') as f:
		writer = csv.writer(f, lineterminator='\n', delimiter = '\t')
		if last == 1:
			writer.writerows([["文ID", "開始位置", "終了位置", "前文脈", "注釈該当部", "後文脈", "品詞カテゴリ"]])
		writer.writerows(output)

def proc(srcfile, outpath):
	# (同一品詞∧同一スパン)を集約して抽出
	srcdata, matchspan = data(srcfile)
	# print(len(srcdata))  # train, test, dev: 8723, 4609, 1658

	# 入れ子除去
	outdata = removeIreko(srcdata, matchspan)
	# print(len(outdata))  # train, test, dev: 8091, 4272, 1560

	# 品詞集約
	outdata = collectPOS(outdata)
	# print(len(outdata))  # train, test, dev: 5820, 3092, 1131
	# print(outdata[("950131057-009", (35, 38))])

	# 出力整形
	output = forAnnotate(outdata)
	# outdata = sortMWE(outdata)

	writeTSV(outpath, output)

def main():
	args = sys.argv

	# output, matchspan, meaninglist = data(fpath, frg=1)
	# countMeaning(list(set(meaninglist)))
	if args[1] == "-ud":
		for ftype in ["train", "test", "dev"]:
			print("ftype: ", ftype)
			fpath = "../../result/ud/ud_matced_{}_1222.csv".format(ftype)
			outpath = "../../result/ud/ud_matced_{}_0128_edited.tsv".format(ftype)
			proc(fpath, outpath)

	elif args[1] == "-bccwj":
		fpath = "../../result/bccwj/bccwj_matced_0128.csv"
		outpath = "../../result/bccwj/bccwj_matced_0128_edited.tsv"
		proc(fpath, outpath)





if __name__ == '__main__':
	main()
