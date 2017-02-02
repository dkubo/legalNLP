# coding: utf-8

import subprocess 
import sys

# ComainuでParse
def parsing(sentence):
	cmd1 = "echo {}".format(sentence)
	cmd2 = "/home/is/daiki-ku/Comainu-0.72/script/comainu.pl plain2longout"
	p1 = subprocess.Popen(cmd1.strip().split(" "), stdout=subprocess.PIPE)
	p2 = subprocess.Popen(cmd2.strip().split(" "), stdin=p1.stdout, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	p1.stdout.close()
	return shape(p2.communicate()[0].decode('utf-8'))

# Comainuの出力結果を整形
def shape(stdout):
	return [part.split("\t") for part in stdout.split("\n")[0:-2]]

def main():
	# TOP20の表現を含む文と，マッチしたスパン，funcかotherかを取得

	
	# sentence = "固有名詞に関する論文を提出した．"
	# result = parsing(sentence)

if __name__ == '__main__':
	main()

