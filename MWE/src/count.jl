#coding:utf-8

using ExcelReaders
#using LightXML
using LibExpat
using DataFrames

"""
JDMWEのエントリとBCCWJのCORE_SUWとのマッチング
Daiki Kubo
2016/7/8

"""

#const BCCWJ_PATH="../data/core_SUW.txt"		←このtsvファイルは使わない
const BCCWJ_ROOT="../data/core_M-XML"
const JDMWE_PATH="../data/JDMWE_idiom v1.3 20121215.xlsx"



#jdmwe = readxlsheet(DataFrame, JDMWE_PATH, "Sheet1", colnames=[:A, :B, :C, :D, :E, :F, :G, :H])
#println(jdmwe)

#トライ木:http://datastructuresjl.readthedocs.io/en/latest/trie.html?highlight=trie


#bccwj = readtable(BCCWJ_PATH, separator='\t', header=false, names=[:register, :sample_id, :chara_start_posi, :chara_end_posi, :order_id, :occur_start_posi, 
#																																		:occur_end_posi, :fixed_frg, :variable_frg, :BI_label, :lemma_table_id, :lemma_id, :lemma, 
#																																		:lForm, :subLemma, :wType, :pos, :cType, :cForm, :formBase, :usage, :orthBase, :orthToken,
#																																		:originalText ,:pronToken])
#println(bccwj)

#XMLファイルオープン
#child = readdir(BCCWJ_ROOT)
#for xfile in child
	xfile="OC01_00001.xml"
	arr = []
	println("--------------------------")
	path = BCCWJ_ROOT*"/"*xfile
	doc = open(path) do fp
		readall(fp)
	end

	#xmlパーズ
	root_node = xp_parse(doc)
	sentence_node = LibExpat.find(root_node,"/mergedSample//sentence")
	for sen_part in sentence_node
		println("--------------------------")
		sen_part = xp_parse(string(sen_part))
		suw_node = LibExpat.find(sen_part,"/sentence/LUW/SUW")
		for suw in suw_node
			try
				@show suw.attr["kana"]
			catch e
				@show suw.attr["formBase"]
			end
		end
	end
#end

#open(file) do bccwj
#	sentence=""
#	for line in eachline(bccwj)
#		data = split(line,'\t')
#    BI_label,formBase,originalText = data[10],data[20],data[24]
#		if BI_label == "B"
#			println(sentence)
#			sentence=formBase
#		else
#			sentence *= formBase
#		end
#	end
#end

