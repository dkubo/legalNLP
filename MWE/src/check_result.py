#coding: utf-8

from collections import defaultdict

# マッチスパンが入れ子or 包含になっているものを確認
# マッチMWEの種類数カウント

RESULT="../result/matced_mwe.csv"

def push(spanobj, ireko):
	if ireko == []:
		ireko.append(spanobj)
	else:
		if not spanobj in ireko:
			ireko.append(spanobj)

	return ireko

def recur(value, ireko):
	for i, (begin, end) in enumerate(value):
		if i == 0:
			beginobj, endobj = begin, end
		else:
			if (beginobj < begin < endobj) or (beginobj < end < endobj):
				spanobj = [(beginobj, endobj), (begin, end)]
				spanobj.sort()
				ireko = push(spanobj, ireko)

	return ireko

def printforireko(output, sentid, ireko):
	global samemweid
	global difmweid

	for span in ireko:
		for i, (_, _, _, mweid_1, meaning_1) in enumerate(output[(sentid, span[0])]):
			for j, (_, _, _, mweid_2, meaning_2) in enumerate(output[(sentid, span[1])]):
				print("-------------------------------------")
				print((sentid, span[0]), output[(sentid, span[0])][i])
				print((sentid, span[1]), output[(sentid, span[1])][j])
				print("-------------------------------------")

				if mweid_1 == mweid_2:
					samemweid += 1
				else:
					difmweid += 1

def irekoCheck(value):
	ireko = []
	for cnt in range(0, len(value)):
		if cnt != 0:
			buf = value[0]
			value[0] = value[cnt]
			value[cnt] = buf
		ireko = recur(value, ireko)

	return ireko

def printforcollect(k, value):
	global samespanid

	print("------------------------")
	for v in value:
		pre, mwe, post, mweid, meaning = v
		samespanid += 1
		print(k, v)
	print("------------------------")

def main():
	meaninglist, matchspan, output = [], defaultdict(list), defaultdict(list)

	with open(RESULT, "r") as f:
		for line in f:
			mweid, sentid, b, e, pre, mwe, post, meaning = \
															line.rstrip().split(",")

			b, e = int(b), int(e)
			output[(sentid, (b,e))].append([pre, mwe, post, mweid, meaning])
			matchspan[sentid].append((b,e))
			meaninglist.append(meaning)

	meaninglist = sorted(set(meaninglist), key=meaninglist.index)
	# print(meaninglist)
	# print(len(meaninglist))		# 29

	# for sentid, v  in matchspan.items():
	# 	if len(v) >= 2:		# 同一の文内で、複数マッチしている場合⇒入れ子等になっている可能性がある
	# 		ireko = irekoCheck(v)
	# 		if ireko != []:
	# 			printforireko(output, sentid, ireko)


	# print('totalpair: ', samemweid + difmweid)
	# print('samemweid: ', samemweid)
	# print('difmweid: ', difmweid)

	for k, value in output.items():
		if len(value) >= 2:
			printforcollect(k, value)

if __name__ == '__main__':
	samemweid, difmweid, samespanid = 0, 0, 0
	main()
