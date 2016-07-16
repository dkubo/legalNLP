#coding:utf-8

import collections
import glob
import argparse


class Sentence(object):

	def __init__(self, sentence):
		self.sentence = sentence

class Query(object):		# class: 何も継承しない場合は,objectを指定する

    def __init__(self, sentence, answer, fact):
        self.sentence = sentence
        self.answer = answer
        self.fact = fact

def normalize(sentence):
	return sentence.lower().replace('.', '').replace('?', '')

def get_wid(vocab, words):
	return [vocab[word] for word in words]

def parse_line(vocab, line):
	if '\t' in line:
		#question line
		q, ans, f_sids = line.split('\t')
		ans_id = get_wid(vocab, [ans])[0]	# ans_id: answerの語彙のid
		q_words = normalize(q).split()
		q_ids = get_wid(vocab, q_words)
		f_sids = map(int, f_sids.split(' '))		# map(a,b): aをbの全要素に適用する
		return Query(q_ids, ans_id, f_sids)
	else:
		#sentence line
		s_words = normalize(line).split()
		s_ids = get_wid(vocab, s_words)
		return Sentence(s_ids)


# 必要なデータ: 語彙数,語彙のid,
def parse_data(path, vocab):
	data = []
	all_data = []
	with open(fpath) as f:
		for line in f:
			# pos: 最初の空白のインデックス
			pos = line.find(' ')	# find(str): strとマッチしたインデックスを返す
			sid = int(line[:pos])	# sid: 文id
			line = line[pos:]			# sidを除去
			if sid == 1 and len(data) > 0:
				all_data.append(data)
				data = []				
			data.append(parse_line(vocab, line))

		if len(data) > 0:
			all_data.append(data)

		return all_data

def get_arg():
	parser = argparse.ArgumentParser(description='converter')
	parser.add_argument('--gpu', type=int, default=-1)
	args = parser.parse_args()
	print args

if __name__ == '__main__':
	get_arg()
	root_path = "../../data/tasks_1-20_v1-2/en"
	vocab = collections.defaultdict(lambda: len(vocab))
#	for data_id in range(1,21):
	data_id = 1
	# glob.glob: マッチしたパスをリストで返す
	fpath = glob.glob('%s/qa%d_*train.txt' % (root_path, data_id))[0]
	train_data = parse_data(fpath, vocab)
	fpath = glob.glob('%s/qa%d_*test.txt' % (root_path, data_id))[0]
	test_data = parse_data(fpath, vocab)
	print('Training data: %d' % len(train_data))		# 文id=1で区切ったデータ数

	#未知語(:k)が引数として与えられた場合、id(:v)を付与する
#	print vocab["I"]
#	print vocab["can"]
#	print vocab["I"]

#	words = ['I','can','fly','!']
#	wid = [vocab[w] for w in words]
#	print wid









