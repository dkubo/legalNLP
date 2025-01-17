#coding:utf-8

# require 'natto'
require 'json'
require 'csv'

# for local
# TSUTUJI = "../20161007/dic/tsutsuji/tsutsuji-1.1/L9_utf8.list"

# for ITC
TSUTUJI = "../data/20161007/dic/tsutsuji/tsutsuji-1.1/L9_utf8.list"
MYDIC = "../result/tsutsuji_dic_20161206.json"	# 先頭の「う」と「ん」を削除、ハイフン処理をした辞書

CONST1="./const/const1_unidic.tsv"
CONST2="./const/const2.tsv"

def getmwe(dict)
	mwelist = Array.new()
	data_hash = JSON.parse(File.read(dict))

	suwcnt, varicnt = 0, 0
	data_hash.each{|mweid, value|
		suwcnt += 1
		# mwelist.push([mweid, value["suw_lemma"], value["left"], value["meaning"]])
		mwelist.push([mweid, value["suw_lemma"], value["left"]])

		for mwe in value["variation_lemma"]
			varicnt += 1
			# mwelist.push([mweid, mwe, value["left"], value["meaning"]])
			mwelist.push([mweid, mwe, value["left"]])
		end
	}
	mwelist.uniq!

	return mwelist
end

# KTCコーパスを一文ずつに分解する
def splitSentence(file)
	sent_hash, suw_list, pre_sentid, sentid = {}, [], "", ""
	corpus = open(file, 'r')

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

def getConst()
	consthash = {}
	file_1 = open(CONST1,'r')
	file_1.each_line{|l|
		c_list = []
		sig, const_list = l.chomp.split("\t")
		const_list.split(";").each{|const|
			c_list.push(const.split(","))
		}
		consthash[sig] = c_list
	}

	file_2 = open(CONST2,'r')
	file_2.each_line{|l|
		new_list = []
		sig, const_list = l.chomp.split("\t")
		const_list.split(";").each{|const|
			if new_list == []
				new_list = consthash[const] unless consthash[const] == nil
			else
				new_list += consthash[const] unless consthash[const] == nil
			end
		}
		consthash[sig] = new_list
	}

	return consthash
end

# カンマ区切りされているデータがある⇒分割
def makeArray(v)
	sentlist, lemlist, poslist, vari1, vari2, sentence, lemma, sentpos = [], [], [], [], [], [], [], []

	v.each{|line|
		sentlist.push(line[8].split(",", -1))
		lemlist.push(line[9].split(",", -1))
		poslist.push(line[10].split(",", -1))
		if line[11] == "" or line[11].split(",", -1).length == 1
			vari1.push(line[11])
		else
				vari1 += line[11].split(",", -1)
		end
		if line[12] == "" or line[12].split(",", -1).length == 1
			vari2.push(line[12])
		else
				vari2 += line[12].split(",", -1)
		end
	}

	sentlist.flatten!
	lemlist.flatten!
	poslist.flatten!

	for i in 0..lemlist.length-1
		if /-.*/ =~ sentlist[i]
			sentence.push($`)
		else
			sentence.push(sentlist[i])
		end
		if /-.*/ =~ lemlist[i]
			lemma.push($`)
		else
			lemma.push(lemlist[i])
		end
		sentpos.push([poslist[i], vari1[i], vari2[i]])
	end

	return sentence, lemma, sentpos
end

def splitCont(mwe, start_idx, sentence)
	precont, matched, postcont = sentence[0..start_idx-1].join(), 
																sentence[start_idx..start_idx+mwe.length-1].join(), 
																sentence[start_idx+mwe.length..-1].join()
	startlen, endlen = precont.length+1, precont.length + matched.length
	return precont, matched, postcont, startlen, endlen
end

# MWEID, 文ID, 開始文字位置, 終了文字位置, 前文脈, 対象表現, 後文脈, MEANING
def	writeCSV(fname, outdata)
	file = CSV.open(fname, 'w')
	outdata.each{|data| file.puts data }
	file.close
end

# def matching(mweid, mwe, leftconst, meaning, s_id, sentence, lemma, sentpos, consthash, outdata)
def matching(mweid, mwe, leftconst, s_id, sentence, lemma, sentpos, consthash, outdata)
	m_frg, leftconst, totallen = 0, leftconst[0].scan(/.{1,2}/), 0

	lemma.each_with_index do |lempart, idx|  	# sentence loop
		if mwe[0] == lempart 	# 文の形態素とMWEの形態素が一部マッチ
			m_frg, start_idx = 1, idx
			startlen, endlen = totallen+1, totallen
			for cnt in 0..mwe.length-1 do
				if lemma[idx+cnt] != mwe[cnt]
					m_frg = 0
					break
				else
					endlen += lemma[idx+cnt].length
				end
			end

			# 品詞等の制約を確認			
			constlist = consthash[leftconst[0]]		# leftconst[1]は全て"90"
			if m_frg == 1
				m_frg = constCheck(constlist, sentpos[start_idx-2], start_idx, m_frg)
				m_frg = constCheck(constlist, sentpos[start_idx-1], start_idx, m_frg) unless m_frg != 0
			end
			# MWEが完全にマッチしたとき
			if m_frg == 1
				precont, matched, postcont, startlen, endlen = splitCont(mwe, start_idx, sentence)		# 出現形の文に対してのstartlen等を取得
				# p "outdata:", outdata
				# p "mweid:", mweid
				# p "s_id:", s_id
				# p "matched:", matched
				# p "precont:", precont
				# p "postcont:", postcont
				# p "meaning:", meaning
				# p startlen, endlen
				outdata.push([mweid, s_id, startlen.to_s, endlen.to_s, precont, matched, postcont])	# startlen, endlen: 標準形の文に対してのもの
				# outdata.push([mweid, s_id, startlen.to_s, endlen.to_s, precont, matched, postcont, meaning])	# startlen, endlen: 標準形の文に対してのもの
				m_frg = 0
			end
		end
		totallen += lempart.length
	end

	return outdata
end

# 制約リスト, 確認対象の品詞等
def constCheck(constlist, sentleft, start_idx, m_frg)	# (辞書側の制約, 文内の品詞等, マッチフラグ)
	constlist.each{|const|
		check = 1
		const = const[0..-2]	# 原形の制約は無視
		const.zip(sentleft).each{|part, pos|
			# 品詞階層の整合性をとる（辞書側の品詞等制約の階層と、実際の文内の品詞等）
			pos = pos.split("-")[0...part.split("-").length].join("-")
			if part == "*" or part == pos 	# "matched!"
				next

			elsif part == "None"	# 文頭に接続詞が来た場合
				if start_idx == 0	# matched!
					next
				else	# not matched!
					check = 0
					break
				end

			else	# not matched!
				check = 0
				break
			end
		}
		if check == 1 then
			m_frg = 1
			break
		else
			m_frg = 0
		end
	}
	return m_frg
end


def proc(pathtocorp, mwelist, consthash, outdata)
	# open the corpus
	sent_hash = splitSentence(pathtocorp)	# train: 6039, test: 2837, dev: 1119

	sent_hash.each{|s_id, v|
		sentence, lemma, sentpos = makeArray(v)
		mwelist.each{|mweid, mwe, leftconst|
			p mwe if mwe.length <= 1
		# mwelist.each{|mweid, mwe, leftconst, meaning|
			outdata = matching(mweid, mwe, leftconst, s_id, sentence, lemma, sentpos, consthash, outdata)
			# outdata = matching(mweid, mwe, leftconst, meaning, s_id, sentence, lemma, sentpos, consthash, outdata)
		}
	}
	return outdata
end

def main()
	# 制約のリスト取得
	consthash = getConst()

	# 各辞書からMWEのリストを取得
	mwelist = getmwe(MYDIC)	# [[mweid, mwe, leftconst, meaning], [], ...]
	# p mwelist.length		# 3609

	# 辞書for文
	for type in ["train", "test", "dev"] do
		outdata = []
		pathtocorp = "../data/20161007/corpus/ud/ja_ktc-ud-#{type}-merged.conll"
		outdata = proc(pathtocorp, mwelist, consthash, outdata)
		result = "../result/matced_#{type}_1206.csv"
		# csv書き込み
		# writeCSV(result, outdata)
	end

end

main()