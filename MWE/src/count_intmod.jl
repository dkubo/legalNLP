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
⇛たまにタグが抽出されてるものがあるから、正規表現で消す(見つけたの：<enclosedCharacter description>,<ruby rubytext>?)
⇛品詞の制約入れる必要あり
・品詞もhashで保持？
match_part = きりがいちばんけんこうにもよいんでしょうけどそういかない
reg_hash[match_mwe] = r.*きりが.*ない
ismatch(reg_hash[match_mwe],match_part) = true
↑これがマッチしてしまう
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
	reg_hash = Dict{UTF8String,Regex}()	#k:mwe,v:mwe_reg
	jdmwe_df = readxlsheet(DataFrame, JDMWE_PATH, "Sheet1", colnames=[:A, :B, :C, :D, :E, :F, :G, :H])
<<<<<<< HEAD
	#@show (jdmwe_df[[301:302,1742:1743,1841:1842,2044:2045,2199:2200,2586:2587,2668:2669,2956:2957,3686:3687,3831:3832,3836:3837],[:A,:B,:C,:D,:E,:F,:G,:H]])
=======
#	@show (jdmwe_df[[301:302,1742:1743,1841:1842,2044:2045,2199:2200,2586:2587,2668:2669,2956:2957,3686:3687,3831:3832,3836:3837],[:A,:B,:C,:D,:E,:F,:G,:H]])
>>>>>>> 3d546ff5359d3960542db8645057bc6dcc0fae20
#	@show (jdmwe_df[[:B,:E]])

	#まずは品詞の制約なし
	lex_cnt = length(jdmwe_df[:B])		#4449
	#.:内部修飾, _:異字種で表記可能
	for mwe in jdmwe_df[:B]
		mwe = replace(mwe,r"(_|-)","")
		mwe_reg = Regex(replace(mwe,r"(\.)",".*"))
		mwe = replace(mwe,r"(\.)","")		#_と先頭の.を消去
<<<<<<< HEAD
##		value = get(reg_hash,mwe,0)
##		if value != 0
##			@show mwe
##		end
=======
#		value = get(reg_hash,mwe,0)			#overlab確認
#		if value != 0
#			@show mwe
#		end
>>>>>>> 3d546ff5359d3960542db8645057bc6dcc0fae20
		reg_hash[mwe] = mwe_reg
		trie[mwe] = cnt
		cnt += 1
	end
	return trie,reg_hash,lex_cnt
end

################################################
#	トライ木探索
################################################
function search_trie(trie,yomi_sentence,reg_hash)
	match_mwe = ""
	pmatch = ""				#マッチした部分下のsubtrie文字列
	match_yomi = []
	index = 1					#マッチ部取得用のインデックス
	index_arr = []		#インデックス保持用
	for yomi in yomi_sentence
		if yomi != ""
			buff = keys_with_prefix(trie, yomi)
			if length(buff) == 1		#マッチ
				push!(index_arr,index)
				trie = subtrie(trie, yomi)
				match_mwe *= yomi
				push!(match_yomi,yomi)
			end
		end
		index += 1
	end
	try
		pmatch = keys(trie)[1]			#完全マッチでない場合
	catch
		match_mwe = ""
	end
	if pmatch != ""
		match_mwe = ""
	else
		#内部修飾の制約を含めたマッチング
		match_part = join(yomi_sentence[index_arr[1]:index_arr[end]])
		if ismatch(reg_hash[match_mwe],match_part) == false
			match_mwe = ""
		end
	end
	return match_mwe,yomi_sentence,match_yomi
end

################################################
#	main
################################################
sen_cnt = 0		#文数カウント
lex_cnt = 0		#エントリ数カウント(idiom:4449)
mwe_cnt = 0		#マッチしたMWEをカウント

matched_mwe_hash = Dict{UTF8String,Int64}()		#マッチしたMWEをカウントする(k:MWE,v:cnt)
<<<<<<< HEAD
trie,reg_hash,lex_cnt = loadMWE()
lex_cnt = length(reg_hash)
#@show reg_hash
#@show subtrie(trie, "")	#trieが返ってくる

##BCCWJ_CORE_M-XMLファイルオープン
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
		match_mwe,yomi_sentence,match_yomi = search_trie(trie,yomi_sentence,reg_hash)
		if match_mwe != ""
			push!(match_array,match_mwe)
		end
#		@show match_yomi
		#他のMWEがマッチする可能性も考慮
		while length(match_yomi) != 0		#部分マッチor完全マッチした場合
			deleteat!(yomi_sentence, findin(yomi_sentence,match_yomi))	#yomi_sentenceからマッチ要素を削除
#				@show yomi_sentence
			match_mwe,yomi_sentence,match_yomi = search_trie(trie,yomi_sentence,reg_hash)
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
			@show yomi_sentence
			@show match_array
		end
		######################################
	end
end
=======
trie,reg_hash,lex_cnt,jdmwe_df_b = loadMWE()


#lex_cnt = length(reg_hash)
##@show reg_hash
##@show subtrie(trie, "")	#trieが返ってくる

##BCCWJ_CORE_M-XMLファイルオープン
#child = readdir(BCCWJ_ROOT)
#for xfile in child
##	println("--------------------------")
#	path = BCCWJ_ROOT*"/"*xfile
#	doc = open(path) do fp
#		readall(fp)
#	end
#	#xmlパーズ
#	root_node = xp_parse(doc)
#	sentence_nodes = LibExpat.find(root_node,"/mergedSample//sentence")
#	for sentence_node in sentence_nodes
#		sen_cnt += 1
##		println("--------------------------")
#		######################################
#		#		初期化
#		######################################
#		origin_sentence = []
#		yomi_sentence = []
#		match_array = []
#		match_yomi = []
#		yomi = ""
#		######################################
#		#		XMLパーズ
#		######################################
#		sentence_node = xp_parse(string(sentence_node))
#		suw_nodes = LibExpat.find(sentence_node,"/sentence//SUW")
#		for suw_node in suw_nodes
#			suw = suw_node.elements[1]
#			push!(origin_sentence,suw)
#			try
#				yomi = suw_node.attr["kana"]
#			catch e
#				yomi = suw_node.attr["formBase"]
#			end
#			push!(yomi_sentence,jcconv.kata2hira(yomi))
#		end
#		######################################
#		#		マッチング
#		######################################
##		yomi_sentence = Any["これ","いじょう","","ああ","いえば","こう","いう","のは","やめて"]
#		match_mwe,yomi_sentence,match_yomi = search_trie(trie,yomi_sentence,reg_hash)
#		if match_mwe != ""
#			push!(match_array,match_mwe)
#		end
##		@show match_yomi
#		#他のMWEがマッチする可能性も考慮
#		while length(match_yomi) != 0		#部分マッチor完全マッチした場合
#			deleteat!(yomi_sentence, findin(yomi_sentence,match_yomi))	#yomi_sentenceからマッチ要素を削除
##				@show yomi_sentence
#			match_mwe,yomi_sentence,match_yomi = search_trie(trie,yomi_sentence,reg_hash)
#			if match_mwe != ""
#				push!(match_array,match_mwe)
#			end
#		end
#		if length(match_array) != 0
#			for matched in match_array
#				value = get(matched_mwe_hash,matched,0)
#				if value == 0			#キーが存在しなかった場合
#					matched_mwe_hash[matched] = 1
#					mwe_cnt += 1
#				else
#					matched_mwe_hash[matched] += 1				
#					mwe_cnt += 1
#				end
#			end
##			@show origin_sentence
##			@show yomi_sentence
##			@show match_array
#		end
#		######################################
#	end
#end
>>>>>>> 3d546ff5359d3960542db8645057bc6dcc0fae20

#@show matched_mwe_hash
########################################
#	統計量計算
########################################
ratio_sen = mwe_cnt/sen_cnt
ratio_lex = mwe_cnt/lex_cnt
mwe_entr = length(matched_mwe_hash)
println("MWE(idiom)出現数/BCCWJ総文数 = "*string(mwe_cnt)*"/"*string(sen_cnt)*"="*string(ratio_sen))
println("MWE(idiom)出現数/MWE(idiom)総数 = "*string(mwe_entr)*"/"*string(lex_cnt)*"="*string(ratio_lex))

##一度も出現していないMWE確認
#for mwe in jdmwe_df_b
#	if in(mwe,keys(matched_mwe_hash)) != false
#		@show mwe
#	end
#end

#一度も出現していないMWE確認
#for mwe in jdmwe_df_b
#	if in(mwe,keys(matched_mwe_hash)) == false
#		@show mwe
#	end
#end


