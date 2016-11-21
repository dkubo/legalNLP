# coding: utf-8

from stanford_corenlp_pywrapper import CoreNLP

def main():
	proc = CoreNLP("pos", corenlp_jars=["/home/is/daiki-ku/opt/stanford-corenlp-full-2016-10-31/*"])
	proc.parse_doc("hello world. how are you?")



if __name__ == '__main__':
	main()
