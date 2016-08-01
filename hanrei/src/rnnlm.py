#coding:utf-8

"""
判決文を使ったRNNLMやってみる

"""
import hanrei_db
import sensplit

import numpy as np
import re
from collections import defaultdict
import argparse
from natto import MeCab
#from sklearn.cross_validation import train_test_split

import chainer
from chainer import links as L
from chainer import functions as F
from chainer import optimizers, cuda


class RNNLM(chainer.Chain):
	def __init__(self, n_vocab, word_embed_size):
		super(RNNLM, self).__init__(
			embed = L.EmbedID(n_vocab, word_embed_size, ignore_label=-1),
			l1 = L.LSTM(word_embed_size, word_embed_size),
			l2 = L.Linear(word_embed_size, n_vocab),
		)
	
	def __call__(self, x, y):
		h0 = self.embed(x)
		h1 = self.l1(h0)
		predict = self.l2(h1)
		return softmax_cross_entropy(predict, y)

	def reset_state(self):
		self.l1.reset_state()

def get_wid(vocab, data):
	return [vocab[word] for word in data], vocab

if __name__ == '__main__':
	path = '../data/hanreiDB'
	vocab = defaultdict(lambda: len(vocab))

# open the DB
	db = hanrei_db.SQLite3(path)
	cur = db.open_db()

# read the data
	sql = "select id, syubunPart from hanrei where id<=150"
#	sql = u"select id, syubunPart, riyuPart from hanrei"
	rows = db.exe_to_db(cur, sql)
	train_data = []
	test_data = []
	nm = MeCab()
	for doc_id, syubunPart in rows:
		print "--------------"
		print "id:", doc_id
	# 改行、空白削除
		syubunPart = re.sub(r'(\n|\t| |　)', '', syubunPart)
	# 文分割
		sensp = sensplit.SenSplit(syubunPart)
		syubun_list = sensp()
		
		for sentence in syubun_list:
			if sentence == '':
				continue
			morph_list = []		# 文を形態素で分割したリスト
			sentence = sentence.encode('utf_8')	# unicode→str(utf-8)
			for n in nm.parse(sentence, as_nodes=True):
				if not n.is_eos():
#					print n.surface
					morph_list.append(n.surface)
			x = []
			y = []
			for i in range(0, len(morph_list)):
				if i == 0:
					x.append('<BOS>')
					y.append(morph_list[i])
				elif  i == len(morph_list)-1:
					x.append(morph_list[i])
					y.append('<EOS>')
				else:
					x.append(morph_list[i])
					y.append(morph_list[i+1])
##				print "x:", x
##				print "y:", y
			x, vocab = get_wid(vocab, x)
			y, vocab = get_wid(vocab, y)
#			for k,v in vocab.iteritems():
#				print k,v
			train_data.append([x,y])
	
# close the DB
	db.close_db()

#	print len(vocab)
	model = RNNLM(len(vocab), 100)
	optimizer = optimizers.Adam()
	optimizer.setup(model)
	
	for epoch in range(5):
		for data in train_data:
			print "-----------------"
			x, y = data
			print x
#			for x, y in data:
#				print x, y
#				loss = model(x, y)
#			print loss




