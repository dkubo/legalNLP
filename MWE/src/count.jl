#coding:utf-8

using ExcelReaders
using PyCall
using LibExpat
using DataFrames
using DataStructures
@pyimport jcconv

#using LightXML

"""
JDMWEのエントリとBCCWJのCORE_SUWとのマッチング
Daiki Kubo
2016/7/8

"""

#const BCCWJ_PATH="../data/core_SUW.txt"		←このtsvファイルは使わない
const BCCWJ_ROOT="../data/core_M-XML"
const JDMWE_PATH="../data/JDMWE_idiom v1.3 20121215.xlsx"

################################################
#	JDMWE読込
################################################
function loadMWE()
	trie = Trie{Int}()			#トライ木宣言
	cnt = 1
	jdmwe_df = readxlsheet(DataFrame, JDMWE_PATH, "Sheet1", colnames=[:A, :B, :C, :D, :E, :F, :G, :H])
	#println(jdmwe_df[[:B,:E]])

	#まずは品詞の制約なし
	#println(length(jdmwe_df[:B]))		#4449
	#.:内部修飾, _:異字種で表記可能
	for mwe in jdmwe_df[:B]
	#	println(split(mwe,"-"))
		mwe = replace(mwe,r"(\.|_|-)","")		#_と先頭の.を消去
#		mwe = replace(mwe,".","-.-")		#先頭以外の.を-.-に置換	
#		mwe = split(mwe,"-")
		trie[mwe] = cnt
		cnt += 1
	end
	return trie
end

################################################
#	トライ木探索
################################################
function search_trie(trie,yomi_sentence)
	match_mwe = ""
	match_yomi = []
	for yomi in yomi_sentence
		buff = keys_with_prefix(trie, yomi)
		if length(buff) == 1		#マッチ
			trie = subtrie(trie, yomi)
			match_mwe *= yomi
			push!(match_yomi,yomi)
		end
	end
	if length(keys(trie)) != 1			#完全マッチでない場合
		match_mwe = ""
	end
	#yomi_sentenceからマッチ要素を削除
	deleteat!(yomi_sentence, findin(yomi_sentence,[match_yomi]))	
	@show yomi_sentence
	return match_mwe,yomi_sentence
end


################################################
#	main
################################################
trie = loadMWE()
#@show trie
#@show subtrie(trie, "")	#trieが返ってくる

#BCCWJ_CORE_M-XMLファイルオープン
child = readdir(BCCWJ_ROOT)
for xfile in child
	println("--------------------------")
	path = BCCWJ_ROOT*"/"*xfile
	doc = open(path) do fp
		readall(fp)
	end
	#xmlパーズ
	root_node = xp_parse(doc)
	sentence_nodes = LibExpat.find(root_node,"/mergedSample//sentence")
	for sentence_node in sentence_nodes
		println("--------------------------")
		######################################
		#		初期化
		######################################
		origin_sentence = []
		yomi_sentence = []
		match_array = []
		yomi = ""
		######################################
		#		XMLパーズ
		######################################
		sentence_node = xp_parse(string(sentence_node))
		suw_nodes = LibExpat.find(sentence_node,"/sentence//SUW")
		for suw_node in suw_nodes
			suw = suw_node.elements[1]
			push!(origin_sentence,suw)
			try
				yomi = suw_node.attr["kana"]
			catch e
				yomi = suw_node.attr["formBase"]
			end
			push!(yomi_sentence,jcconv.kata2hira(yomi))
		end
		######################################
		#		マッチング
		######################################
		match,yomi_sentence = search_trie(trie,yomi_sentence)
#		push!(match_array,match)
#		while match != ""		#他のMWEがマッチする可能性も考慮
#			match = search_trie(trie,yomi_sentence)
#			push!(match_array,match)
#		end
#		@show origin_sentence
#		@show yomi_sentence
#		@show match_array
		######################################
	end
end












