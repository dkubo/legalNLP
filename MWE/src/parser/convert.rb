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

def getMatchhash()
	matchhash = Hash.new { |h,k| h[k] = [] }

	for ftype in ["train", "test", "dev"]
		matchinfo = "../../result/ud/ud_matced_#{ftype}_1222_rmoneword_naibu.tsv"

		file = open(matchinfo, 'r')
		file.each_line{|l|
			mweid = l.split("\t")[-1].chomp.split(",")
			sentid = l.split("\t")[1]
			sposi = l.split("\t")[2]
			eposi = l.split("\t")[3]
			matchhash[sentid].push([mweid, sposi, eposi])
		}
	end
	return matchhash
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

# mwe部分を一つにまとめたことによるword idのずれを修正
def fixwid(newvalues)
	for i in 0..newvalues.length-1
		newvalues[i][0] = (i + 1).to_s
	end
	return newvalues
end

# 異なる品詞で，包含になってる部分がある → スパンが長い方を採用
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

def fixsentpart(newvalues, headword, newpos)
	newvalues[-1][1], newvalues[-1][2] = headword, headword
	newvalues[-1][3], newvalues[-1][4] = newpos, newpos
	newvalues[-1][5], newvalues[-1][6] = "_", "_"
	newvalues[-1][8], newvalues[-1][9] = headword, headword
	newvalues[-1][13], newvalues[-1][14] = headword, headword
	# p newvalues
	return newvalues
end

def sentloop(sentence, m, newpos, jsondict)
	totallen, m_frg, headword = 0, 0, ""
	mweid, sposi, eposi = m
	newvalues = []

	sentence.each{|sentpart|
		if totallen + 1 == sposi.to_i
			m_frg = 1
			newvalues.push(sentpart)
		elsif totallen == eposi.to_i
			m_frg = 0
			if headword == ""
				p jsondict[m[0][0]]["headword"]
			end
			newvalues = fixsentpart(newvalues, headword, newpos)
		end

		if m_frg == 1
			headword += sentpart[1]
		else
			newvalues.push(sentpart)
		end
		totallen += sentpart[1].length
	}
	return newvalues
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

		return "oh no"
	else
		# 格助詞型(P), とりたて詞型(T) 提題助詞型(W), 形式名詞型(N) => ADP
		# 連体助詞型(D) => ADP
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

# mwe部分を一つにまとめる
def genPart(matched, sentence, jsondict)
	matched.each{|m|
		# p m
		newpos = getpos(m[0])
		# if newpos == "oh no"
		# 	p m[0], sentence
		# end
		sentence = sentloop(sentence, m, newpos, jsondict)
		sentence = fixwid(sentence)
	}
	return sentence
end

def main()
	data = ProcData.new()
	todict = "../../result/tsutsuji_dic_20161215.json"
	tocorp = "../../result/ud/parser/mwes_1228.conll"

	matchhash = getMatchhash()	# k: sentid, v: [[mweid, sposi, eposi], ..]
	senthash = splitSentence(tocorp)
	new_senthash = Marshal.load(Marshal.dump(senthash))	# deep copy
	jsondict = loadDict(todict)

	senthash.each{|sentid, sentence|
		# if sentid == "950220031-019"
		# 	p "sentid: " + sentid
		# 	p matchhash[sentid]
		# end

		if matchhash[sentid].length > 1
			matchedidx = hoganCheck(matchhash[sentid])
			new_senthash[sentid] = genPart(matchedidx, sentence, jsondict)
		else
			new_senthash[sentid] = genPart(matchhash[sentid], sentence, jsondict)
		end
	}
	# result="../../result/ud/parser/convert_mwes_1228.conll"
	# writeCSV(result, new_senthash)
end

main()
