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

################################################
#	JDMWE読込
################################################
function loadMWE(mwe_path, dicnum)
	lex_cnt = 0				# MWEエントリ数カウント
	entrynum = 0
	trie = Trie{Int}()			# トライ木宣言
	cnt = 1
	colstart = "2"
	reg_hash = Dict{UTF8String, Regex}()		#k:mwe,v:mwe_reg
#	if dicnum in ["2", "10", "11", "13", "16"]
#		col_list = [:A, :B, :C, :D, :E, :F, :G, :H, :I, :J, :K]
#	elseif dicnum in ["18"]
#		col_list = [:A, :B, :C, :D, :E, :F, :G, :H, :I, :J, :K, :L, :M, :N, :O, :P, :Q, :R, :S, :T, :U, :V, :W, :X, :Y, :Z, :AA, :AB, :AC, :AD, :AE, :AF, :AG, :AH, :AI, :AJ, :AK, :AL, :AM]
#	else
#		col_list = [:A, :B, :C, :D, :E, :F, :G, :H, :I, :J]
#	end

	@show dicnum
	if dicnum == "1"
		entrynum = "23610"
	elseif dicnum == "2"
		entrynum = "35930"
	elseif dicnum == "3"
		entrynum = "13913"
	elseif dicnum == "4"
		entrynum = "3741"
	elseif dicnum == "5"
		entrynum = "4808"
	elseif dicnum == "6"
		entrynum = "2593"
	elseif dicnum == "7"
		entrynum = "16271"
	elseif dicnum == "8"
		entrynum = "16651"
	elseif dicnum == "9"
		entrynum = "1275"
	elseif dicnum == "10"
		entrynum = "4934"
	elseif dicnum == "11"
		entrynum = "2749"
	elseif dicnum == "12"
		entrynum = "4546"
	elseif dicnum == "13"
		entrynum = "4052"
	elseif dicnum == "14"
		entrynum = "13071"
	elseif dicnum == "16"
		entrynum = "472"
	elseif dicnum == "17"
		# entrynum = "3208"
		entrynum = "3497"
	elseif dicnum == "18"
		colstart = "3"
		# entrynum = "1062"
		entrynum = "1085"
	elseif dicnum == "19"
		# entrynum = "46"
		entrynum = "179"
	end


	if dicnum in ["2", "3", "6", "7", "17"]
		sheet = "sheet1"
	else
		sheet = "Sheet1"
	end

	@show sheet
	@show entrynum
#	@show col_list
#	jdmwe_df = readxlsheet(DataFrame, mwe_path, sheet, colnames = col_list)
	jdmwe_df = readxl(DataFrame, mwe_path, header=false, sheet*"!C"*colstart*":C"*entrynum, colnames=[:C])

#	@show (jdmwe_df[[:B, :E]])
#	@show names(jdmwe_df)

	#.:内部修飾, _:異字種で表記可能
	for mwe in jdmwe_df[:C]
		@show mwe
		mwe = replace(mwe, r"(_|-)", "")
		mwe_reg = Regex(replace(mwe, r"(\.)", ".*"))
		mwe = replace(mwe ,r"(\.)", "")		#_と先頭の.を消去
		@show mwe_reg
		# value = get(reg_hash, mwe, 0)			#overlab確認
		# if value != 0
		# 	@show mwe
		# end
		reg_hash[mwe] = mwe_reg
		trie[mwe] = cnt
		cnt += 1
	end
#	@show lex_cnt
	return trie, reg_hash
end

################################################
#	トライ木探索
################################################
function search_trie(trie, yomi_sentence, reg_hash)
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
		# 内部修飾の制約を含めたマッチング
		match_part = join(yomi_sentence[index_arr[1]:index_arr[end]])
		if ismatch(reg_hash[match_mwe],match_part) == false
			match_mwe = ""
		end
	end
	return match_mwe, yomi_sentence, match_yomi
end

########################
#  write
########################
function writeFile(text)
	# 追記
	open("result_add.txt", "a") do fp
		write(fp, string(text)*"\n")
	end
end

################################################
#		main
################################################
# 辞書再帰読込
cnt = 0
mwe_root = "../data/JDMWE_dict/"
cur = readdir(mwe_root)
for fname in cur
	m = match(r"^[0-9]{1,2}", fname)
	if m != nothing
		dicnum = m.match
		@show dicnum
		# writeFile("dicnum:"*string(dicnum))
		sen_cnt = 0             #文数カウント
		lex_cnt = 0             #エントリ数カウント
		mwe_cnt = 0             #マッチしたMWEをカウント
		matched_mwe_hash = Dict{UTF8String,Int64}()	#マッチしたMWEをカウントする(k:MWE,v:cnt)
		# load MWE dic
		trie, reg_hash = loadMWE(mwe_root * fname, dicnum)
		lex_cnt = length(reg_hash)
		# @show subtrie(trie, "")	#trieが返ってくる

		# open BCCWJ
		child = readdir(BCCWJ_ROOT)
		for xfile in child
		 	path = BCCWJ_ROOT * "/" * xfile
		 	doc = open(path) do fp
		 		readall(fp)
		 	end

		 	# xmlパーズ
		 	root_node = xp_parse(doc)
		 	sentence_nodes = LibExpat.find(root_node, "/mergedSample//sentence")

		 	# sentence parse
		 	for sentence_node in sentence_nodes
		 		sen_cnt += 1
		 		origin_sentence = []
		 		yomi_sentence = []
		 		match_array = []
		 		match_yomi = []
		 		yomi = ""

		 		sentence_node = xp_parse(string(sentence_node))
		 		suw_nodes = LibExpat.find(sentence_node, "/sentence//SUW")
		 		for suw_node in suw_nodes	# suw parse
		 			suw = suw_node.elements[1]
		 			push!(origin_sentence, suw)
		 			try
		 				yomi = suw_node.attr["kana"]
		 			catch e
		 				yomi = suw_node.attr["formBase"]
		 			end
		 			push!(yomi_sentence, jcconv.kata2hira(yomi))
		 		end

		 		# search
		 		match_mwe, yomi_sentence, match_yomi = search_trie(trie, yomi_sentence, reg_hash)
		 		if match_mwe != ""
		 			push!(match_array, match_mwe)
		 		end

		 		# 他のMWEがマッチする可能性も考慮
		 		while length(match_yomi) != 0		# 部分マッチor完全マッチした場合
		 			deleteat!(yomi_sentence, findin(yomi_sentence, match_yomi))	#yomi_sentenceからマッチ要素を削除
		 			match_mwe, yomi_sentence, match_yomi = search_trie(trie, yomi_sentence, reg_hash)
		 			if match_mwe != ""
		 				push!(match_array, match_mwe)
		 			end
		 		end


		 		if length(match_array) != 0
		 			for matched in match_array
		 				value = get(matched_mwe_hash, matched, 0)
		 				if value == 0			#キーが存在しなかった場合
		 					matched_mwe_hash[matched] = 1
		 					mwe_cnt += 1
		 				else
		 					matched_mwe_hash[matched] += 1				
		 					mwe_cnt += 1
		 				end
		 			end
#		 			@show origin_sentence
#		 			@show yomi_sentence
#		 			@show match_array
		 		end

		 	end
		end

		@show matched_mwe_hash
		# writeFile("matched_mwe_hash:"*string(matched_mwe_hash))
		# #######################################
		# #	統計量計算
		# #######################################
		ratio_sen = mwe_cnt / sen_cnt
		# ratio_lex = mwe_cnt / lex_cnt
		mwe_entr = length(matched_mwe_hash)
		ratio_lex = mwe_entr / lex_cnt
		# writeFile("ratio_lex:"*string(ratio_lex))
		# @show ratio_lex
		println("MWE出現数/BCCWJ総文数 = "*string(mwe_cnt)*"/"*string(sen_cnt)*"="*string(ratio_sen))
		println("MWE出現数/MWE総数 = "*string(mwe_entr)*"/"*string(lex_cnt)*"="*string(ratio_lex))
		# writeFile(string(mwe_cnt)*"/"*string(sen_cnt)*"="*string(ratio_sen))
		# writeFile(string(mwe_entr)*"/"*string(lex_cnt)*"="*string(ratio_lex))

		# 一度も出現していないMWE確認
		# for mwe in jdmwe_df_b
		#  	if in(mwe, keys(matched_mwe_hash)) != false
		#  		@show mwe
		#  	end
		# end
	end
end

