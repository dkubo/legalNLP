#coding:utf-8

import numpy as np
import argparse
import collections
import data

import chainer
from chainer import links as L
from chainer import functions as F
from chainer import optimizers, cuda

# モデル定義
class RNNLM(chainer.Chain):
	def __init__(self, n_vocab, word_emd_size):
		super(RNNLM, self).__init__(
			embed = L.EmbedID(n_vocab, word_emd_size, ignore_label=-1),
			l1 = L.LSTM(word_emd_size, word_emd_size),
			l2 = L.LSTM(word_emd_size, word_emd_size),
			l3 = L.Linear(word_emd_size, n_vocab),
		)
	
	def __call__(self, x, ans, train):
		h0 = self.embed(x)
		h1 = self.l1(h0)
		h2 = self.l2(h1)
		y = self.l3(h2)
		if train:
			return F.softmax_cross_entropy(y, ans)
		else:
			return F.accuracy(y, ans)
	
	def reset_state(self):
		self.l1.reset_state()
	
def proc(iter_list, train):
	toral_loss = 0.0
	total_acc = 0.0
	cnt = 0
	for batch_data in iter_list:
		accum_loss = None
		batch_data = np.array(batch_data, dtype=np.int32)
#		print "batch_data.shape:", batch_data.shape
#		print "batch_data.T.shape:", batch_data.T.shape
		batch_data = batch_data.T

		# train
		if train:
			print "--------------"
			for i in range(len(batch_data)-1):
#				print batch_data[i], batch_data[i+1]
				loss = model(batch_data[i], batch_data[i+1], train=True)
				toral_loss += loss.data
				if accum_loss is None:
					accum_loss = loss
				else:
					accum_loss += loss					
		# test
		else:
			for i in range(len(batch_data)-1):
				cnt += 1
				acc = model(batch_data[i], batch_data[i+1], train=False)
				total_acc += acc.data
				
		if accum_loss is not None:
			model.zerograds()
			accum_loss.backward()
			optimizer.update()
			
	if train:
		print "toral_loss:", toral_loss
	else:
		print "toral_acc:", total_acc / cnt
		 	
def padding(data):
	pad_data = []
	for sentence in data:
		if len(sentence) != sentence_maxlen:
			pad_time = sentence_maxlen - len(sentence)
			for _ in range(pad_time):
				sentence.append(-1)
		pad_data.append(sentence)
	return pad_data


# 引数処理
def get_arg():
	parser = argparse.ArgumentParser()
	parser.add_argument('--gpu', '-gpu', default=-1, type=int)
	args = parser.parse_args()
	return args

# 引数取得
args = get_arg()

vocab = collections.defaultdict(lambda: len(vocab))

# データ取得
train_data, test_data, vocab = data.get_data(vocab)
sentence_maxlen = max(len(sentence) for sentence in train_data)
train_data = padding(train_data)
test_data = padding(test_data)
# numpy型に変換
train_data = np.array(train_data, dtype=np.int32)
test_data = np.array(test_data, dtype=np.int32)

# 語彙数
n_vocab = len(vocab)

# モデル
model = RNNLM(n_vocab,5)

if args.gpu >= 0:
	model.to_gpu()
	xp = cupy
else:
	xp = np

# Setup an optimizer
optimizer = optimizers.Adam()
optimizer.setup(model)

batch_size = 2
for epoch in range(100):
	print "epoch:", epoch
	train_iter = chainer.iterators.SerialIterator(train_data, batch_size, repeat=False)
	test_iter = chainer.iterators.SerialIterator(test_data, batch_size, repeat=False, shuffle=False)
	proc(train_iter, train=True)
	proc(test_iter, train=False)





