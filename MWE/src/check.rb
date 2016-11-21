#coding: utf-8

require 'natto'

# for itc server
UD = "../data/20161007/corpus/ud/ja_ktc-ud-train-merged.conll"
HOME = "/home/is/daiki-ku/Desktop/github/legalNLP/MWE"
UNIDIC = "/home/is/daiki-ku/usr/lib/mecab/dic/unidic"

# for local
# UD = "/home/daiki/デスクトップ/CS/20161007/corpus/ud/ja_ktc-ud-train-merged.conll"

# def parsing(nm_ipa, nm_uni, sentence)
def parsing(nm_uni, sentence)
	mwe_list = []
	# puts "------------------------------------------"
	# puts "○Result of ipadic"
	# nm_ipa.parse(sentence) do |n|
	# 	puts "#{n.surface}\t#{n.feature.split(",")[0..6]}"
	# end 
	# puts "------------------------------------------"
	# puts "○Result of unidic"
	nm_uni.parse(sentence) do |n|
		# 標準系をpush
		lemma = n.feature.split(",")[7]
		mwe_list.push(lemma) unless lemma == "*"
		# 出現形をpush
		# mwe_list.push(n.surface) unless n.surface == ""
		# puts "#{n.surface}\t#{n.feature.split(",")[0..5].push(n.feature.split(",")[7])}"
	end 
	return mwe_list
end

def getarg()
	return ARGV[0], ARGV[1]
end

# KTCコーパスを一文ずつに分解する
def splitSentence(file=UD)
	sent_hash, suw_list = {}, []
	pre_sentid, sentid = "", ""
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
			suw_list.push(l)
		end
	}
	sent_hash[pre_sentid] = suw_list
	return sent_hash
end

def matching(mwe, sentence)
	m_frg, matchspan = 0, []		# マッチフラグ, マッチインデックスの範囲
	sentence.each_with_index do |s,idx|  	# sentence loop
		if mwe[0] == s # 文の形態素とMWEの形態素が一部マッチ
			m_frg, m_idx = 1, idx
			for cnt in 0..mwe.length-1 do
				if sentence[idx+cnt] != mwe[cnt]
					m_frg = 0
					break
				end
			end
			if m_frg == 1
				##############################################
				matchspan.push([m_idx, m_idx+mwe.length])
				##############################################
				m_frg = 0
			end
		end
	end
	return matchspan
end

def printConst()

end

# 出力を目で確認、品詞・活用等の制約を対応付ける(IPA, UNIDIC)
def checkConst(matchspan, foroutput, sentence, opt)
	p "============================================="
	p "sentence: " + sentence.join()
	p "---------------------------------------------"
	matchspan.each{|span|
		if opt == "-l"
			if foroutput[span[0]-2..span[1]] == []
				p foroutput
			else
				p foroutput[span[0]-2..span[1]]
			end
		else
			if foroutput[span[0]..span[1]+2] == []
				p foroutput
			else
				p foroutput[span[0]..span[1]+2]
			end
		end
	}
end

def main()

	# 引数処理
	opt, mwe = getarg()

	# MWEを形態素単位に分割
	# nm_ipa = Natto::MeCab.new(dicdir: IPADIC)
	nm_uni = Natto::MeCab.new(dicdir: UNIDIC)
	mwe_list = parsing(nm_uni, mwe)
	p mwe_list

	# UDを文単位で抽出
	sent_hash = splitSentence(UD)

	sent_hash.each{|s_id, v|
		sentence, poslist, katuyogata, katuyokei, sentlemma = [], [], [], [], []
		# foroutput = Hash.new { |h,k| h[k] = [] }
		foroutput = []
		v.each{|line|
			# 出現形: line[8], 語彙素: line[9], 品詞: line[10], 活用型: line[11], 活用形: line[12]
			poslist.push(line[10]) unless line[10] == nil
			katuyogata.push(line[11]) unless line[11] == nil
			katuyokei.push(line[12]) unless line[12] == nil
			if /-.*/ =~ line[9]
				sentlemma.push($`)
			elsif line[9] != nil
				sentlemma.push(line[9])
			end
			if /-.*/ =~ line[8]
				sentence.push($`)
			elsif line[8] != nil
				sentence.push(line[8])
			end
		}
		sentence.flatten!		# 10列目以降のカンマ区切りに対応
		poslist.flatten!
		katuyogata.flatten!
		katuyokei.flatten!

		sentence.each_with_index{|sent, i|
			foroutput.push([poslist[i], katuyogata[i], katuyokei[i], sentlemma[i]])
			# foroutput.push([sent, poslist[i], katuyogata[i], katuyokei[i], sentlemma[i]])
		}

		# Matching MWE on the corpus(UD)
		matchspan = matching(mwe_list, sentlemma)	# output: the list of [startidx, endidx]

		# Output the result
		checkConst(matchspan, foroutput, sentence, opt) unless matchspan == []
	}

end

main()