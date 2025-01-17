#coding:utf-8

"""
Comp.txtを読んで、json形式に整形
tsutsuji1.1_utf-8.xml
"""
require 'json'
require 'natto'
require 'nokogiri'
require 'open3'
require 'yaml'

# for local
# HOME = "/home/daiki/Desktop/CS"
# COMAINU = HOME + "/20161007/dic/coma/Comp.txt"
# TSUTSUJI = HOME + "/20161007/dic/tsutsuji/tsutsuji-1.1/tsutsuji1.1_utf8_edit.xml"

# for itc
HOME = "/home/is/daiki-ku/Desktop/github/legalNLP/MWE"
COMAINU = HOME + "/data/20161007/dic/coma/Comp.txt"
TSUTSUJI = HOME + "/data/20161007/dic/tsutsuji/tsutsuji-1.1/tsutsuji1.1_utf8_edit.xml"

CONST1="./const/const1_unidic.tsv"
CONST2="./const/const2.tsv"

# RESULT_DIC="../result/tsutsuji_dic_20161206.json"

def getdict(fname)
	if fname == COMAINU
		lines = []
		file = open(fname, 'r')
		file.each_line{|l|
			lines.push(l.chomp.split("\t"))
		}
		return lines
	elsif fname == TSUTSUJI
		xml_doc = Nokogiri::XML(File.open(fname))
		return xml_doc
	end
end

def nm_init()
	return Natto::MeCab.new
end

def parsing_mecab(nm, mwe)
	suw_lem, suw_lem_yomi, suw_lem_pos = [], [], []
	nm.parse(mwe) do |n|
		pos = n.feature.split(',')[0,3].join('-').gsub(/-\*/, "")
		suw_lem.push(n.feature.split(',')[7]) unless n.surface == ""
		suw_lem_yomi.push(n.feature.split(',')[6]) unless n.surface == ""# or yomi == "*"
		suw_lem_pos.push(pos) unless n.surface == ""
	end
	suw_lem = checkHyphen(suw_lem)
	return suw_lem, suw_lem_yomi, suw_lem_pos
end

# unidicでの解析結果にハイフンが含まれる場合がある⇒対処
def checkHyphen(lemma)
	lemmanew = []
	lemma.each{|part|
		if /-/ =~ part
			lemmanew.push($`)
		else
			lemmanew.push(part)
		end
	}
	return lemmanew
end

# comainuの出力を整形する
def shaping(std_out)
	n_list, nn_list = [], []
	std_out.each{|part|
		if /\n$/ =~ part
			nn_list.push($`)		# 前方参照
			n_list.push(nn_list)
			nn_list = []
		else
			nn_list.push(part)
		end
	}
	n_list.push(nn_list)
	return n_list
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

def getAttribute(l, attri)
	return l.attribute(attri).value
end

def writeJSON(fname, hash)
	File.open(fname, "w") do |f|
		f.write(JSON.pretty_generate(hash))
	end
end

def constPush(sig_list, const, consthash)
	for i in 0..1 do
		sig_list[const]["#{const[i]}"] = consthash[const[i]].uniq unless sig_list[const]["#{const[i]}"] != ""
	end
	return sig_list
end

def getpath()
	return ARGV[0].chomp
end

###########################
# main
###########################
def main()
	todict = getpath()
	nm = nm_init()
	sig_list, g_hash = {}, {}
	s_cnt, s_one_cnt, v_cnt, v_one_cnt, v_cnt_2, v_cnt_3 = 0, 0, 0, 0, 0, 0
	pos_hash = {"P"=>"格助詞型", "Q"=>"接続助詞型", "D"=>"連体助詞型", "C"=>"接続詞型", "M"=>"助動詞型", "N"=>"形式名詞型", "T"=>"とりたて詞型", "W"=>"提題助詞型"}
	consthash = getConst()

	xml_doc = getdict(TSUTSUJI)
	xml_doc.remove_namespaces!		# 名前空間を除去する(nokogiriだとめんどくさいことになる)

	xml_doc.xpath('//ENTRIES//L2').each{|l2|
		meaning = getAttribute(l2, "MEANING")
		left = getAttribute(l2, "LEFT")
		# sig_list[left] = {"#{left[0]}" => "", "#{left[1]}" => "", "LEFT"=>[], "RIGHT"=>[]} unless sig_list[left] != nil
		# constPush(sig_list, left, consthash)

		l2.xpath('.//L3').each{|l3|
			l_hash = Hash.new()
			entry = getAttribute(l3, "BASE").delete(".")
			# sig_list[left]["LEFT"].push(entry)
			pos_id = getAttribute(l3, "L3ID")
			l3id = getAttribute(l3, "L1to3ID")
			suw_lemma, suw_lemma_yomi, suw_lemma_pos = parsing_mecab(nm, entry)
			if suw_lemma.length != 1
				l_hash["headword"], l_hash["global_pos"], l_hash["meaning"] = entry, pos_hash[pos_id], meaning
				l_hash["suw_lemma"], l_hash["suw_lemma_yomi"], l_hash["suw_lemma_pos"] = suw_lemma, suw_lemma_yomi, suw_lemma_pos

				l_hash["variation"], l_hash["variation_lemma"], l_hash["left"] = [], [], []
				# l_hash["variation"], l_hash["variation_lemma"], l_hash["left"], l_hash["right"] = [], [], [], []
				l_hash["left"].push(left)

				# l3.xpath('.//L7').each{|l7|
					# right = getAttribute(l7, "RIGHT")
					# l_hash["right"].push(right)
					# sig_list[right] = {"#{right[0]}" => "", "#{right[1]}" => "", "LEFT"=>[], "RIGHT"=>[]} unless sig_list[right] != nil
					# constPush(sig_list, right, consthash)

				l3.xpath('.//L9').each{|l9|
				# l7.xpath('.//L9').each{|l9|
					variation = l9.text.delete(".\s\n")
					# sig_list[right]["RIGHT"].push(variation)
					if variation != entry
						v_suw_lem, _, _ = parsing_mecab(nm, variation)
						if v_suw_lem.length != 1
							l_hash["variation"].push(variation)
							l_hash["variation_lemma"].push(v_suw_lem)
						end
					end
				}
			# }
				# l_hash["right"].uniq!
				l_hash["left"].uniq!
				l_hash["variation"].uniq!
				l_hash["variation_lemma"].uniq!
				g_hash[l3id] = l_hash

			end
		}
	}
	# p s_cnt, s_one_cnt, v_cnt,v_cnt_2, v_cnt_3

	# puts JSON.pretty_generate(g_hash)
	writeJSON(todict, g_hash)

end

main()
