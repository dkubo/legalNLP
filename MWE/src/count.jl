#coding:utf-8

using ExcelReaders
using LibExpat
using DataFrames
using DataStructures
using PyCall
@pyimport jcconv

#using LightXML

"""
JDMWEのエントリとBCCWJのCORE_SUWとのマッチング
Daiki Kubo
2016/7/8
・To do
⇛内部修飾句に対する制約：col. Eを使う(MWEの外は制約なくてもよさげ？文法規則的に無くても問題なさそう)
※内部修飾しなくてもOKということに注意
・アルゴリズム案：
1.まずは、トライ木を探索する(今のアルゴリズムで)
2.マッチング(トライ木の探索)の際に、マッチした語のインデックスを取得
3.マッチしたMWEの内部の語の配列を取得(i.e. array[2(マッチ始め):4(マッチ終わり)])
if マッチしたMWE(array[2:4])==goldのMWEとなる
	MWEである
else(gold≠match)
	4.マッチしたMWEのcol.(B/E)?を参照
	if 内部修飾できない
		MWEでない
	else(内部修飾可能)
		5.内部修飾句の配列要素の品詞をマッチング
		if 品詞が全てマッチ
			MWEである
		else
			MWEでない
		end
	end
end

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
sen_cnt = 0		#文数カウント
lex_cnt = 0		#エントリ数カウント(idiom:4449)
mwe_cnt = 0		#マッチしたMWEをカウント

matched_mwe_hash = Dict{UTF8String,Int64}()		#マッチしたMWEをカウントする(k:MWE,v:cnt)
trie,lex_cnt = loadMWE()
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
#		yomi_sentence = Any["これ","いじょう","","ああ","いえば","こう","いう","のは","やめて"]
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
			for matched in match_array
				value = get(matched_mwe_hash,matched,0)
				if value == 0			#キーが存在しなかった場合
					matched_mwe_hash[matched] = 1
					mwe_cnt += 1
				else
					matched_mwe_hash[matched] += 1				
					mwe_cnt += 1
				end
			end
			@show origin_sentence
#			@show yomi_sentence
			@show match_array
#			@show matched_mwe_hash
		end
		######################################
	end
end

@show matched_mwe_hash
########################################
#	統計量計算
########################################
ratio_sen = mwe_cnt/sen_cnt
ratio_lex = mwe_cnt/lex_cnt
println("MWE(idiom)出現数/BCCWJ総文数 = "*mwe_cnt*"/"*sen_cnt*"="*ratio_sen)
println("MWE(idiom)出現数/MWE(idiom)総数 = "*mwe_cnt*"/"*lex_cnt*"="*ratio_lex)









