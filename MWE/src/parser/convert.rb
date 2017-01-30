# coding: utf-8

require 'json'
require '../countoken/data'
require 'csv'

"""
複合辞が含まれている文の
5	に	_	ADP	ADP	_	4	case	_	_
6	つい	_	VERB	VERB	_	27	advcl	_	_
7	て	_	SCONJ	SCONJ	_	6	mark	_	_
8	は	_	ADP	ADP	_	6	dep	_	_

を，複合辞辞書を使って

5 について について ADP ADP _ _
6 は は ADP ADP _ _

に変換する
"""
CONST1="../const/const1_unidic.tsv"
CONST2="../const/const2.tsv"

def splitSentence(tocorp)
	sent_hash, lasthash = Hash.new(), Hash.new()

	suw_list, pre_sentid, sentid, label = [], "", "", "B"
	lemmasent, sentence, sentpos = [], [], []
	corpus = open(tocorp, 'r')
	corpus.each_line{|l|
		l = l.chomp.split("\t")
		if /# SENT-ID: / =~ l[0]
			sentid = $'
			if suw_list != []
				sent_hash[pre_sentid] = suw_list
				suw_list = []
			end
			pre_sentid = sentid
		else
			suw_list.push(l) unless l == []
		end
	}
	sent_hash[pre_sentid] = suw_list
	return sent_hash
end

def loadDict(dict)
	jsondict = {}
	File.open(dict, 'r') do |file|
		jsondict = JSON.load(file)
	end
	return jsondict
end

def	writeCSV(fname, data)
	File.open(fname, "w") do |file|
		data.each{|sentid, sentence|
			file.puts("# SENT-ID: #{sentid}")
			for part in sentence
				file.puts(part.join("\t"))
			end
			file.puts("\n")
		}
	end
end

def getMatchhash()
	matchhash = Hash.new { |h,k| h[k] = [] }
	for ftype in ["train", "test", "dev"]
		matchinfo = "../../result/ud/ud_matced_#{ftype}_0128_edited.tsv"

		file = open(matchinfo, 'r')
		file.each_line{|l|
			posids = []
			tmp = l.chomp[1..-2].split("\t")
			mweids = tmp[-1].split(",")
			mweids.each{|mweid|
				posids.push(mweid[-1])
			}
			posids.uniq!
			sentid, sposi, eposi = tmp[0], tmp[1], tmp[2]
			matchhash[sentid].push([posids, sposi, eposi])
		}
	end
	return matchhash
end

# 異なる品詞で，包含になってる部分がある場合 → スパンが長い方を採用
def hoganCheck(matchedidx)
	new_matchedidx = Marshal.load(Marshal.dump(matchedidx))
	for i in 0..matchedidx.length-1
		for j in i+1..matchedidx.length-1
			mweid1, sposi1, eposi1 = matchedidx[i]
			mweid2, sposi2, eposi2 = matchedidx[j]
			if sposi1 == sposi2 
				if eposi1 > eposi2
					new_matchedidx.delete([mweid2, sposi2, eposi2])
				elsif eposi2 > eposi1
					new_matchedidx.delete([mweid1, sposi1, eposi1])
				end
			end
		end
	end
	return new_matchedidx
end

def getpos(mweid)
	incfrg = 0
	if mweid.length >= 2
		mweid.each{|mid|
			if ["P", "T", "W", "N", "D"].include?(mid[-1])
				incfrg = 1
			else
				incfrg = 0
				break
			end
		}
		if incfrg == 1
			return "ADP"
		else
			mweid.each{|mid|
				if ["Q", "C"].include?(mid[-1])
					incfrg = 1
				else
					incfrg = 0
					break
				end
			}
			if incfrg == 1
				return "SCONJ"
			end
		end
		return "nil"
	else
		# 格助詞型(P), とりたて詞型(T) 提題助詞型(W), 形式名詞型(N), 連体助詞型(D) => ADP
		if ["P", "T", "W", "N", "D"].include?(mweid[0][-1])
			return "ADP"
		# 接続助詞型(Q), 接続詞型(C) => SCONJ
		elsif ["Q", "C"].include?(mweid[0][-1])
			return "SCONJ"
		# 助動詞型(M) => AUX
		elsif ["M"].include?(mweid[0][-1])
			return "AUX"
		end
	end
end

def fixsentpart(newvalues, headword, newpos)
	newvalues[-1][1], newvalues[-1][2] = headword, headword
	newvalues[-1][3], newvalues[-1][4] = newpos, newpos
	# newvalues[-1][5], newvalues[-1][6] = "_", "_"
	# newvalues[-1][5], newvalues[-1][6] = "_", "_"	# 暫定的に適当に付ける
	newvalues[-1][5], newvalues[-1][6] = "_", newvalues[-1][0].to_i-2	# 暫定的に適当に付ける
	newvalues[-1][7] = "mwe"
	newvalues[-1][8], newvalues[-1][9] = headword, headword
	newvalues[-1][13], newvalues[-1][14] = headword, headword
	# p newvalues
	return newvalues
end

def sentloop(sentence, m, newpos, jsondict, sentid)
	newvalues, totallen, m_frg, headword = [], 0, 0, ""
	_, sposi, eposi = m

	if sentid == "950131057-009"
		p sposi, eposi
	end
	sentence.each{|sentpart|
		if totallen + 1 == sposi.to_i
			m_frg = 1
			newvalues.push(sentpart)
		elsif totallen == eposi.to_i
			m_frg = 0
			# if sentid == "950131057-009"
			# 	p headword
			# end
			newvalues = fixsentpart(newvalues, headword, newpos)
		end

		if m_frg == 1
			headword += sentpart[1]
		else
			newvalues.push(sentpart)
		end
		totallen += sentpart[8].length
		# totallen += sentpart[1].length # 2列目を使うと，文字スパンが合わない箇所がある(もとのUDコーパスのミスが原因)
		if sentid == "950131057-009"
			p "---------------------------"
			p sentpart[1]
			p totallen
		end
	}
	return newvalues
end

# mwe部分を一つにまとめたことによるword idのずれを修正
def fixwid(sentence)
	for i in 0..sentence.length-1
		sentence[i][0] = (i + 1).to_s
	end
	return sentence
end

# mwe部分を一つにまとめる
def genPart(matched, sentence, jsondict, sentid)
	matched.each{|m|
		# 品詞対応付け(DICT⇒UD)
		newpos = getpos(m[0])
		# 一つにまとめる
		sentence = sentloop(sentence, m, newpos, jsondict, sentid)
		# word_idのずれを修正
		sentence = fixwid(sentence)
	}
	return sentence
end

def main()
	todict = "../../result/tsutsuji_dic_20161215.json"
	tocorp = "../../result/ud/parser/mwes_1228.conll"

	# データ抽出
	matchhash = getMatchhash()	# k: sentid, v: [[mweid, sposi, eposi], ..]
	senthash = splitSentence(tocorp)
	new_senthash = Marshal.load(Marshal.dump(senthash))	# deep copy
	jsondict = loadDict(todict)

	# マッチング
	senthash.each{|sentid, sentence|
		# p matchhash[sentid]	# [[["M","Q"], "34", "36"], [["P","Q"], "39", "42"]],...]
		if matchhash[sentid].length > 1
			# 入れ子になってたら長いスパンを採用
			matchedidx = hoganCheck(matchhash[sentid])
			# if sentid == "950131057-009"
			# 	p matchedidx
			# end
			# mwe部分を一つにまとめる
			new_senthash[sentid] = genPart(matchedidx, sentence, jsondict, sentid)
		# else
		# 	new_senthash[sentid] = genPart(matchhash[sentid], sentence, jsondict)
		end
	}
	p new_senthash["950131057-009"]
	# result="../../result/ud/parser/convert_mwes_0128.conll"
	# writeCSV(result, new_senthash)
end

main()
