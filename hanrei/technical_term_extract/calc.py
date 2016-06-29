#coding:utf-8
#コーパスから専門用語を判定して抽出するコード
#作成者:magunesium
#作成日:2014/8/10(金)

import MeCab
import csv
import sys
import codecs
import re
import os
from collections import defaultdict
import glob
import math


# //////////////////////////////////////////////////////////////////////////////////////
#　形態素解析して品詞情報と位置情報を共にハッシュで返す
#　入力するテキストが長すぎるとSegmentation fault(コアダンプ)になるので,1ファイルずつ形態素解析にかける
# //////////////////////////////////////////////////////////////////////////////////////
def analysis(text,offset_p,offset_w,position,corpus,word_list):
	tagger = MeCab.Tagger('-Ochasen')		#形態素解析
	node = tagger.parseToNode(text)
	while node:
		try:
			hinsi = str(node.feature.split(",")[0])
			word = str(node.surface)
			#offset_wにkeyが存在しない場合
			if not word in offset_w:
				offset_w[word] = list(str(position))			#文字列型のみリストに型変換可能
			#keyが既に存在するならば
			else:
				offset_w[word].append(str(position))
			offset_p[position] = word
			corpus[word] = hinsi
			word_list.append(word)
			position += 1
			node = node.next
		except:
			continue
	return corpus,offset_p,offset_w,word_list,position

# /////////////////////////////////////////////
# ハッシュ初期化用関数(L=2の場合)
# fをカウント
# word_list_l2 : key:ワード ,value:あるワード(n_i)の後に続くワード(n_i+1)
# word_list_l2[some_word] = [next_word,next_word,.....] 
# 複合名詞(CN) = 単名詞1(n_1) + 単名詞2(n_2)
# /////////////////////////////////////////////
def initialize_word_list(word_list,corpus,offset_p,offset_w):
	word_list_l2 = {}
	f = defaultdict(int)
	for word in word_list:
		if corpus[word] == '名詞':
			position_list = offset_w[word]
			for word_posi in position_list:
				word_posi = int(word_posi)
				if corpus[offset_p[word_posi+1]] == '名詞':
					next_word = offset_p[word_posi+1]
					CN = word + next_word
					#複合名詞CNの前後に名詞が連接していない場合
					if word_posi != 0:
						if corpus[offset_p[word_posi-1]] != '名詞' and corpus[offset_p[word_posi+2]] != '名詞':
							f[CN]+=1
					#word_list_l2のkeyにwordが存在しない場合
					if not word in word_list_l2:
						word_list_l2[word] = list(next_word)
					else:
						word_list_l2[word].append(next_word)
	return word_list_l2	,f,offset_w

# //////////////////////////////////
#　ディレクトリ再帰処理
# ///////////////////////////////////
def fild_all_files(directory):
    for root, dirs, files in os.walk(directory):
        yield root
        for file in files:
            yield os.path.join(root, file)

# ////////////////////////////////////////////////////////////////////////////////
#　LDN,LN,RDN,RNをカウントして名詞ごとに返す(L=1 : 単名詞から専門用語を判定する)
# ////////////////////////////////////////////////////////////////////////////////
def cnt(corpus,offset_p,offset_w,word_list):
	LN = defaultdict(int)
	RN = defaultdict(int)
	LDN_i = {}
	RDN_i = {}
	for n_i in word_list:
		LDN_i[n_i] = []
		RDN_i[n_i] = []
	f = defaultdict(int)
	for n_i in word_list:
		if corpus[n_i] == '名詞':		#名詞が見つかった場合
			position_list = offset_w[n_i]
			for word_posi in position_list:
				word_posi = int(word_posi)
				#後ろの単語が名詞だった場合
				if corpus[offset_p[word_posi+1]] == '名詞':
					next_word = offset_p[word_posi+1]
					RN[n_i] += 1
					#右方連接種類カウント(後で重複消去)
					RDN_i[n_i].append(offset_p[word_posi+1])
					#前の単語が名詞だった場合
				if word_posi != 0:
					if corpus[offset_p[word_posi-1]] == '名詞':
						pre_word = offset_p[word_posi-1]	
						LN[n_i] += 1
						#左方連接種類カウント(後で重複消去)
						LDN_i[n_i].append(offset_p[word_posi-1])
	#LDN,RDN = cnt_ldn_rdn(LDN_i,RDN_i,word_list)
	#return LN,RN,LDN,RDN,f
	return LN,RN


# //////////////////////////////////////
#　重複を消去してLDN,RDNをカウントする
# //////////////////////////////////////
def cnt_ldn_rdn(LDN_i,RDN_i,word_list):
	LDN = defaultdict(int)
	RDN = defaultdict(int)
	for n_i in word_list:
		#重複消去してリストの長さを取得
		LDN[n_i] = len(list(set(LDN_i[n_i])))
		RDN[n_i] = len(list(set(RDN_i[n_i])))
	return LDN,RDN

# //////////////////////////////////////////////////////////////////////
#　LR_nを計算(L=2,連接頻度LN,RNをスコアとした場合)
# //////////////////////////////////////////////////////////////////////
def calc_lr_n_lnrn_l2(word_list_l2,LN,RN,f):
	LR_n = defaultdict(int)
	#単語ごとにスコア計算
	#if word_list_l2
	for word in word_list_l2.keys():
		LR_n[word] = (float(LN[word])+1)*(float(RN[word])+1)
	return LR_n 

# //////////////////////////////////////////////////////////////////////
#　LR_nを計算(L=2,連接種類LDN,RDNをスコアとした場合)
# //////////////////////////////////////////////////////////////////////
def calc_lr_n_ldnrdn_l2(word_list_l2,LDN,RDN,f):
	LR_n = defaultdict(int)
	#単語ごとにスコア計算
	for word in word_list_l2.keys():
		LR_n[word] = (float(LDN[word])+1)*(float(RDN[word])+1)
	return LR_n

# ////////////////////////////////////////////////////////
#	出現頻度を考慮した重み付けスコアFLRを計算
# ////////////////////////////////////////////////////////
def calc_flr_l2(LR_n,f,word_list_l2,length):
	FLR = defaultdict(int)
	LR = defaultdict(int)
	for word,next_word_list in word_list_l2.iteritems():
		for next_word in next_word_list:
			CN = word + next_word
			LR[CN] = math.pow((LR_n[word]+LR_n[next_word]),(1.0/4.0))
			FLR[CN] = f[CN] * LR[CN]		
	return FLR

# //////////////////////////////////
#　main
# ///////////////////////////////////
#約1万件の判例データをコーパスとする
FILE_PATH = "/home/daiki/デスクトップ/intron/technical_term_extract/sample_corpus/"
#FILE_PATH = "/home/daiki/デスクトップ/intron/hourei_scraping/scraping/民事法/"
def main():
	test_txt = ''	#ドキュメント初期化
	cnt_files = 0
	corpus = {}				#corpus,key:ワード,value:ワードの品詞
	offset_w = {}			#offset_p,key:ワードのオフセット,value:ワード
	offset_p = {}			#corpus,key:ワード,value:ワードの品詞
	position = 0
	word_list = []
	#再帰処理ファイルオープン
	#r = re.compile("html")
	r = re.compile("txt")
	for file in fild_all_files(FILE_PATH):
		m = r.search(file)
		if m == None:
			continue
		else:
	#ファイルオープン
	#for file in glob.glob(FILE_PATH+"*.html"):
			fname = file.split('/')
			print "-----------------------------------"
			print fname[-1]
			#f = codecs.open(file,"r","utf-8")
			f = open(file,"r")
			test_txt = ''	#ドキュメント初期化
			#1つずつ法律条文を読み込む
			cnt_files += 1
			print str(cnt_files) +"file"
			for row in f:	#1行ずつ読み込み
				test_txt = test_txt + row
			test_txt = re.sub('(。)|(「)|(」)|(\()|(\))|(\（)|(\）)|(、)|(-)|(，)|(〔)|(〕)|(｢)|(｣)|([a-zA-Z])','',test_txt)
			#前後の空白消去
			test_txt.strip
			#HTMLタグ消去
			#test_txt = re.sub('<.*?>','',test_txt)
			#形態素解析
			corpus,offset_p,offset_w,word_list,position = analysis(test_txt,offset_p,offset_w,position,corpus,word_list)
	#記号消去(括弧消去)
	#test_txt = re.sub('([!-~]|[a-z]|[A-Z])','',test_txt)
	#単語の品詞情報やオフセットなどを位置情報などを取得
	word_list_l2,f,offset_w = initialize_word_list(word_list,corpus,offset_p,offset_w)
	#単名詞のLN,RN等をカウント
	#LN,RN,LDN,RDN,f = cnt(corpus,offset_p,offset_w,word_list,cn_list_l2)
	LN,RN = cnt(corpus,offset_p,offset_w,word_list)
	#スコアを連接頻度とした場合
	LR_n = calc_lr_n_lnrn_l2(word_list_l2,LN,RN,f)
	#スコアを連接種類とした場合
	#LR_n = calc_lr_n_ldnrdn_l2(word_list_l2,LDN,RDN,f)
	#FLRを計算
	length = len(word_list_l2.keys())
	FLR = calc_flr_l2(LR_n,f,word_list_l2,length)
	#スコアの高い順にソートしてトップ2000まで出力
	out_cnt = 0
	for CN,score in sorted(FLR.items(),key=lambda x:x[1],reverse=True):
		out_cnt += 1
		if out_cnt == 2001:
			break
		else:
			#専門用語抽出結果出力
			match = re.search("(原告)|(本件)|(とおり)|(ため)|(よう)|(結果)|(以下)|(当時)|(前記)|(場合)|(当該)|(上記)|([0-9０１２３４５６７８９])|(それぞれ)|(うち)|(それ)|(ところ)|(こと)|(これ)",CN)
			if match is None:
				print str(out_cnt)+"/"+str(length),CN,score
			else:
				out_cnt -= 1
				continue

if __name__ == "__main__":
	main()


