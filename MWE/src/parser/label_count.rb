# coding: utf-8
"""
ラベルカウント
マッピング後の増加トークン数カウントする
"""
def getMatchhash()
	matchhash = Hash.new { |h,k| h[k] = [] }

	for ftype in ["train", "test", "dev"]
		# matchinfo = "../../result/ud/ud_matced_#{ftype}_1222_rmoneword_naibu.tsv"
		# matchinfo = "../../result/ud/ud_matced_#{ftype}_1222_rmoneword_naibu.tsv"
		matchinfo = "../../result/ud/ud_matced_#{ftype}_0114_tokencount.tsv"

		file = open(matchinfo, 'r')
		file.each_line{|l|
			mweid = l.split("\t")[-1].chomp.split(",")
			sentid = l.split("\t")[1]
			sposi = l.split("\t")[2]
			eposi = l.split("\t")[3]
			matchhash[sentid].push([sposi, eposi])
		}
	end
	return matchhash
end

def splitSentence(tocorp, sent_hash)
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


def main()
	matchhash = getMatchhash()
	sent_hash = Hash.new()

	for type in ["dev", "test", "train"]
		fpath = "../../data/20161007/corpus/ud/ja_ktc-ud-#{type}-merged.conll"
		sent_hash = splitSentence(fpath, sent_hash)
	end

	# 金山さんの論文におけるmwe頻度: 806 (トークン数)
	# mwe = 0
	# sent_hash.each{|k, v|
	# 	v.each{|part|
	# 		label = part[7]
	# 		if label == "mwe"
	# 			mwe += 1
	# 		end
	# 	}
	# }
	# p mwe 	# 2645 (ラベル総数, HPと同じ数になった: http://universaldependencies.org/ja/dep/mwe.html)

	"""
	マッチした箇所が，元のUDでは何のラベル化を調べることでカウント
	"""
	cnt, total, buf = 0, 0, 0
	mwe_matchcount = Hash.new { |h,k| h[k] = 0 }
	matchhash.each{|k, spans|
		spans.uniq!
		spans.each{|span|
			total += 1
			len, frg, mwe, labels = 0, 0, [], []
			sentence = ""
			p "sentence id:" + k
			sent_hash[k].each{|part|
				# p part[1]#.split("-")[0].delete("\s")
				str, label = part[1], part[7]
				len += str.length
				sentence += str
				if len >= span[0].to_i and len <= span[1].to_i
					mwe.push(str)
					labels.push(label)
				end
			}
			if not labels.include?("mwe")
				if labels != []
					cnt += 1
					# p labels		# ← ここをカウント！！
				end
			else
				# p mwe		
				mwe_matchcount[mwe] += 1
				# p labels
				buf += 1
			end
		}
	}
	p total, cnt, buf 	# 5625/7032 (マッチしたトークンで，元のUDにmweラベルがついていないトークン)

	# check = 0
	# sorted = mwe_matchcount.sort {|(k1, v1), (k2, v2)| v2 <=> v1 }
	# sorted.each{|k, n|
	# 	check += n
	# }
end

main()
