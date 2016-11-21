#coding:utf-8

import os
import re
import data

def fild_all_files(directory):
	for root, dirs, files in os.walk(directory):
		for file in files:
			if os.path.splitext(file)[1] == u'.xlsx':
				matchOB = re.match(r"^[0-9]{1,2}", file)
				if matchOB:
					yield os.path.join(root, file), matchOB.group()


def main():
	cnt = 0
	mwe_root = "../data/JDMWE_dict/"
	# 辞書再帰読込
	for file, dicnum in fild_all_files(mwe_root):
		# load MWE dict
		print "##############dicnum:", dicnum, "##############"
		data.parse_dict(file, dicnum)
		# print file




if __name__ == '__main__':
	main()