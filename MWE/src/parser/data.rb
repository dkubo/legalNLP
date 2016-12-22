# coding: utf-8

require '../countoken/data'
# require 'json'
require 'csv'

# get sentences including mwes
def getids(toresult)
	trainids = []
	file = open(toresult, 'r')
	file.each_line{|l|
		trainids.push(l.split("\t")[0])
	}
	return trainids
end

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
	return sent_hash
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

# split data into train, dev and mwesentences
def splitdata(sent_hash, trainids, devratio=0.2)
	train, dev, mwes, otherids = {}, {}, {}, []
	totalids = sent_hash.keys()
	otherids = totalids - trainids

	# split others into train and dev
	devlen = (otherids.length*devratio).ceil
	devidx = (0..otherids.length-1).to_a.shuffle.take(devlen)
	trainidx = (0..otherids.length-1).to_a - devidx

	for ids in trainids
		mwes[ids] = sent_hash[ids]
	end
	for ids in trainidx
		train[otherids[ids]] = sent_hash[otherids[ids]]
	end
	for ids in devidx
		dev[otherids[ids]] = sent_hash[otherids[ids]]
	end
	return train, dev, mwes
end


def main()
	data = ProcData.new()
	trainids = []
	sent_hash = {}

	for ftype in ["train", "test", "dev"]
		p ftype
		tocorp = "../../data/20161007/corpus/ud/ja_ktc-ud-#{ftype}-merged.conll"
		toresult = "../../result/ud/ud_annotation_#{ftype}_1222.tsv"
		sent_hash = sent_hash.merge(splitSentence(tocorp))
		trainids = trainids + getids(toresult)
		trainids.uniq!
	end
	train, dev, mwes = splitdata(sent_hash, trainids)

	["train", "test", "mwes"].zip([train, dev, mwes]){|ftype, data|
		writeCSV("../../result/ud/parser/#{ftype}.conll", data)
	}

end



main()