#coding:utf-8

import collections
import glob
import copy
import argparse
import numpy as np
import data
import cupy

from chainer import cuda, Variable
from chainer import functions as F
from chainer import links as L
from chainer import optimizers


"""
python train.py --gpu 0

"""
class Memory(object):
	



class MemNN(chainer.Chain):
	def __init__(self, n_units, n_vocab, max_memory=15):
		super(MemNN, self).__init__(
			E1=L.EmbedID(n_vocab, n_units),  # encoder for inputs
			E2=L.EmbedID(n_vocab, n_units),  # encoder for inputs
			E3=L.EmbedID(n_vocab, n_units),  # encoder for inputs
			E4=L.EmbedID(n_vocab, n_units),  # encoder for inputs
			T1=L.EmbedID(max_memory, n_units),  # encoder for inputs
			T2=L.EmbedID(max_memory, n_units),  # encoder for inputs
			T3=L.EmbedID(max_memory, n_units),  # encoder for inputs
			T4=L.EmbedID(max_memory, n_units),  # encoder for inputs
		)
		# Adjacent (A_k+1=C_k)
		self.M1 = Memory(self.E1, self.E2, self.T1, self.T2)	# 1層目
		self.M2 = Memory(self.E2, self.E3, self.T2, self.T3)	# 2層目
		self.M3 = Memory(self.E3, self.E4, self.T3, self.T4)	# 3層目
		# Adjacent (B = A_1)
		self.B = self.E1
		# 重みのランダム初期化 (平均0,標準偏差0.1の正規分布)
		init_params(self.E1, self.E2, self.E3, self.E4,
				    self.T1, self.T2, self.T3, self.T4)

def init_params(*embs):	# *: 引数をリストとして受け取る
    for emb in embs:
	    emb.W.data[:] = np.random.normal(0, 0.1, emb.W.data.shape)


def convert_data(before_data, gpu):
	d = []	# story: 15 → [[3通常文(mem), 1質問文, 1答え],[6通常文(mem), 1質問文, 1答え],...]
	# 文の最長単語数を求める
	sentence_maxlen = max(max(len(s.sentence) for s in story) for story in before_data)
	for story in before_data:
		mem = np.zeros((50, sentence_maxlen), dtype=np.int32)		# mem: 50×sentence_maxlenのint32のゼロ行列
		mem_length = np.zeros(50, dtype=np.int32)		# mem_length: 50次元のベクトル
		i = 0
		for sent in story:
#			# isinstance(object, class): objectがclassのインスタンスかどうか
			if isinstance(sent, data.Sentence):
				if i == 50:		# The capacity of memory is restricted to the most 50 sentence(1ストーリーあたり50文まで記憶する)
					mem[0:i-1, :] = mem[1:i, :]		# 一番古い情報をシフトする(1〜49→0〜48にシフト)
					# print mem[0,0:3]	# 0行目の0〜2列を取得
					mem_length[0:i-1] = mem_length[1:i]
					i -= 1
				mem[i, 0:len(sent.sentence)] = sent.sentence
				mem_length[i] = len(sent.sentence)
				i += 1
			elif isinstance(sent, data.Query):
				# question sentence
				query = np.zeros(sentence_maxlen, dtype=np.int32)	# 質問文ベクトル
				query[0:len(sent.sentence)] = sent.sentence
				if gpu >= 0:	# gpu
					d.append((cuda.to_gpu(mem),cuda.to_gpu(query),sent.answer))
				else:
					d.append((copy.deepcopy(mem),(query),sent.answer))

	return d


def get_arg():
	parser = argparse.ArgumentParser(description='converter')
	parser.add_argument('-gpu','--gpu', type=int, default=-1)
	args = parser.parse_args()
	return args

if __name__ == '__main__':
	gpu = get_arg().gpu
	print 'gpu:',gpu
	root_path = "../../data/tasks_1-20_v1-2/en"
	# 未知語(:k)が引数として与えられた場合、id(:v)を付与する
	vocab = collections.defaultdict(lambda: len(vocab))
#	for data_id in range(1,21):
	data_id = 1
	# glob.glob: マッチしたパスをリストで返す
	fpath = glob.glob('%s/qa%d_*train.txt' % (root_path, data_id))[0]
	train_data = data.parse_data(fpath, vocab)
	fpath = glob.glob('%s/qa%d_*test.txt' % (root_path, data_id))[0]
	test_data = data.parse_data(fpath, vocab)
	print('Training data: %d' % len(train_data))		# 文id=1で区切ったとき(story)のデータ数
	train_data = convert_data(train_data, gpu)
	test_data = convert_data(test_data, gpu)








