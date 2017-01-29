# coding: utf-8

from collections import defaultdict
"""
分野ごとに，マッチしたMWE
"""


def main():
	srcpath = "../../result/bccwj/bccwj_matced_0128_edited.tsv"
	fieldfrq = defaultdict(int)		# マッチトークン数カウント用ハッシュ

	with open(srcpath, 'r') as f:
		for line in f:
			print("------------------")
			buf = line.rstrip()[1:-1].split("\t")
			print(buf)
			field = buf[0][0:2]
			# fieldfrq[field] += 1	# ドメインごとにマッチトークン数カウント
	# print(fieldfrq)

if __name__ == '__main__':
	main()

