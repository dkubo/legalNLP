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
	lex_cnt = 0				#MWEエントリ数カウント
	trie = Trie{Int}()			#トライ木宣言
	cnt = 1
	jdmwe_df = readxlsheet(DataFrame, JDMWE_PATH, "Sheet1", colnames=[:A, :B, :C, :D, :E, :F, :G, :H])
#	println(jdmwe_df[[:B,:E]])

	#まずは品詞の制約なし
	lex_cnt = length(jdmwe_df[:B])		#4449
	#.:内部修飾, _:異字種で表記可能
	for mwe in jdmwe_df[:B]
	#	println(split(mwe,"-"))
		mwe = replace(mwe,r"(\.|_|-)","")		#_と先頭の.を消去
#		mwe = replace(mwe,".","-.-")		#先頭以外の.を-.-に置換	
#		mwe = split(mwe,"-")
		trie[mwe] = cnt
		cnt += 1
	end
	return trie,lex_cnt
end

################################################
#	トライ木探索
################################################
function search_trie(trie,yomi_sentence)
	match_mwe = ""
	pmatch = ""				#マッチした部分下のsubtrie文字列
	match_yomi = []
#	@show yomi_sentence
	for yomi in yomi_sentence
		if yomi != ""
			buff = keys_with_prefix(trie, yomi)
			if length(buff) == 1		#マッチ
				trie = subtrie(trie, yomi)
				match_mwe *= yomi
				push!(match_yomi,yomi)
			end
		end
	end
	try
		pmatch = keys(trie)[1]			#完全マッチでない場合
	catch
		match_mwe = ""
	end
	if pmatch != ""
		match_mwe = ""
	end
#	@show yomi_sentence
#	@show match_mwe
	return match_mwe,yomi_sentence,match_yomi
end

################################################
#	main
################################################
trie,lex_cnt = loadMWE()
sen_cnt = 0		#文数カウント
#@show trie
#@show subtrie(trie, "")	#trieが返ってくる

#BCCWJ_CORE_M-XMLファイルオープン
child = readdir(BCCWJ_ROOT)
for xfile in child
#	println("--------------------------")
	path = BCCWJ_ROOT*"/"*xfile
	doc = open(path) do fp
		readall(fp)
	end
	#xmlパーズ
	root_node = xp_parse(doc)
	sentence_nodes = LibExpat.find(root_node,"/mergedSample//sentence")
	for sentence_node in sentence_nodes
		sen_cnt += 1
#		println("--------------------------")
		######################################
		#		初期化
		######################################
		origin_sentence = []
		yomi_sentence = []
		match_array = []
		match_yomi = []
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
		yomi_sentence = Any["これ","いじょう","","ああ","いえば","こう","いう","のは","やめて"]
		match_mwe,yomi_sentence,match_yomi = search_trie(trie,yomi_sentence)
		if match_mwe != ""
			push!(match_array,match_mwe)
		end
#		@show match_yomi
		#他のMWEがマッチする可能性も考慮
		while length(match_yomi) != 0		#部分マッチor完全マッチした場合
			deleteat!(yomi_sentence, findin(yomi_sentence,match_yomi))	#yomi_sentenceからマッチ要素を削除
#				@show yomi_sentence
			match_mwe,yomi_sentence,match_yomi = search_trie(trie,yomi_sentence)
			if match_mwe != ""
				push!(match_array,match_mwe)
			end
		end
		if length(match_array) != 0
			@show origin_sentence
			@show yomi_sentence
			@show match_array
		end
		######################################
	end
end

























