#coding:utf-8

using ExcelReaders
using PyCall
#using LightXML
using LibExpat
using DataFrames

@pyimport jcconv

"""
JDMWEのエントリとBCCWJのCORE_SUWとのマッチング
Daiki Kubo
2016/7/8

"""

#const BCCWJ_PATH="../data/core_SUW.txt"		←このtsvファイルは使わない
const BCCWJ_ROOT="../data/core_M-XML"
const JDMWE_PATH="../data/JDMWE_idiom v1.3 20121215.xlsx"

########################
#		JDMWE読込
########################
jdmwe_df = readxlsheet(DataFrame, JDMWE_PATH, "Sheet1", colnames=[:A, :B, :C, :D, :E, :F, :G, :H])
#println(jdmwe_df[[:B,:E]])

#まずは品詞の制約なし
#println(length(jdmwe_df[:B]))		#4449
#.:内部修飾, _:異字種で表記可能
for mwe in jdmwe_df[:B]
#	println(split(mwe,"-"))
	mwe = replace(mwe,"_","")		#_を消去
	mwe = replace(mwe,".","-.-")		#先頭以外の.を-.-に置換	
	mwe = split(mwe,"-")
	filter!(e->e≠"",mwe)
	println(mwe)
end
#トライ木:http://datastructuresjl.readthedocs.io/en/latest/trie.html?highlight=trie

########################
#		BCCWJ読込
########################
#BCCWJ_CORE_M-XMLファイルオープン
#child = readdir(BCCWJ_ROOT)
#for xfile in child
##	xfile="OC01_00001.xml"
#	println("--------------------------")
#	path = BCCWJ_ROOT*"/"*xfile
#	doc = open(path) do fp
#		readall(fp)
#	end
#	#xmlパーズ
#	root_node = xp_parse(doc)
#	sentence_nodes = LibExpat.find(root_node,"/mergedSample//sentence")
#	for sentence_node in sentence_nodes
#		println("--------------------------")
#		sentence = []
#		yomi_sentence = []
#		yomi = ""
#		suw = ""
#		sentence_node = xp_parse(string(sentence_node))
#		suw_nodes = LibExpat.find(sentence_node,"/sentence//SUW")
#		for suw_node in suw_nodes
#			suw = suw_node.elements[1]
#			push!(sentence,suw)
#			try
#				yomi = suw_node.attr["kana"]
#			catch e
#				yomi = suw_node.attr["formBase"]
#			end			
#			push!(yomi_sentence,jcconv.kata2hira(yomi))
#		end
##		@show path
##		@show sentence
##		@show yomi_sentence
#	end
#end



