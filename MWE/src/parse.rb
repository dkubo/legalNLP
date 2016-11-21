#coding:utf-8

require "natto"		# for using mecab
require 'socket'
require './juman.rb'
# require "juman"		# バグがありそう、使えない

KTC = "../20161007/corpus/ud/ja_ktc-ud-train-merged.conll"

def getSid(type="coma")
	shash = {}
	if type == 'coma'
		path = "../matched_id_comainu.csv"
	elsif type == 'tsutsuji'
		path = "../matched_id_tsutsuji.csv"
	end
	file = open(path, 'r')
	file.each_line{|l|
		mwe = l.chomp.split(",")[0]
		sid = l.chomp.delete("[]\"\s").split(",")[1..-1]
		if sid != []
			shash[mwe] = sid
		end
	}
	return shash
end

# KTCコーパスを一文ずつに分解する
def splitSentence(file=KTC)
	sent_hash = {}
	suw_list = []
	corpus = open(file, 'r')
	corpus.each_line{|l|
		l = l.chomp.split("\t")
		if /# SENT-ID: / =~ l[0]
			sentid = $'
			if suw_list != []
				sent_hash[sentid] = suw_list
				suw_list = []
			end
		elsif l != []
			suw_list.push(l)
		end
	}
	return sent_hash
end


def parsing(sentence, juman_s)
	puts "****parse using Mecab****"
	nm = Natto::MeCab.new
	nm.parse(sentence) do |n|
		puts "#{n.surface}\t#{n.feature}"
	end

	puts "****parse using Juman****"
	jumanresult = juman_s.juman_parse(sentence)
	for juman in jumanresult do
		print juman
	end
end

def main()
	juman_s = JumanParser.new('test')
	juman_s.juman_socket("localhost", 32000, '-e2')
	sent_hash = splitSentence()
	shash = getSid()
	shash.each{|mwe, sid|
		puts "---------------------------"
		for mwe_id in sid do
			sentence = ""
			puts "######sentence id: " + mwe_id.to_s + "######"
			puts "mwe:" + mwe
			lines = sent_hash[mwe_id]
			for line in lines do
				if /-.*/ =~ line[2]
					sentence += $`
				else
					sentence += line[2]
				end
			end
			puts "sentence: " + sentence
			parsing(sentence, juman_s)
		end
	}

end

main()