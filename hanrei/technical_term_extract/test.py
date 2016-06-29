#coding:utf-8
import glob
import codecs
import re

#FILE_PATH = "/home/daiki/デスクトップ/intron/scraping_data/"


#for file in glob.glob(FILE_PATH+"*.txt"):
#	fname = file.split('/')
#	f = codecs.open(file,"r","utf-8")
#	test_txt = ''	#ドキュメント初期化
	#1つずつ法律条文を読み込む
#	for row in f:	#1行ずつ読み込み
			#row = re.sub('[!-/:-~]|[a-zA-Z0-9０-９]|[『』「」（）()、，．。,.]','',row)
#			print "before :"+row
#			row = re.sub('０１２３４５６７８９','',row)
#			print "after  :"+row
#			test_txt = test_txt + row
#	f.close()
	#print test_txt

#! /usr/bin/python
# -*- coding: utf-8 -*-

# 簡易エンコーディング判別スクリプト
# 日本語関係のエンコーディングのみチェックする
# 7bitどうしの判別(ASCIIとISO-2022-JPなど)はできない仕様

# CC0

import sys
import os

def simple_chardet(in_str):
  """
  簡易的なエンコーディング判別
  各コーデックに対してデコードを試みる
  成功したものが正しいエンコーディングとなる
  """
  try:
    in_str.decode('iso-2022-jp')
    return '7bit (ascii, iso-2022-jp, etc...)'
  except UnicodeDecodeError:
    try:
      in_str.decode('utf-8')
      return 'utf-8'
    except UnicodeDecodeError:
      try:
        in_str.decode('cp932')
        return 'cp932'
      except UnicodeDecodeError:
        try:
          in_str.decode('euc-jp')
          return 'euc-jp'
        except UnicodeDecodeError:
          return None

if len(sys.argv) != 2:
  print 'USAGE: %s [FILE]' % sys.argv[0]
  sys.exit(0)

infile = sys.argv[1]

# ファイルサイズが大きすぎないかチェック
try:
  size = os.stat(infile).st_size
  if size > 1 * 1024 * 1024:  # 1MiBを上限とする
    print 'Error: file "%s" is too large(%d bytes).' % (infile, size)
    sys.exit(1)
except OSError, (errno, msg):
  print 'Error: cannot stat file "%s": %s [%d]' % (infile, msg, errno)
  sys.exit(1)

# ファイルを開く
try:
  f_in = open(infile, 'r')
except IOError, (errno, msg):
  print >> sys.stderr, 'Error: cannot open file "%s": %s [%d]' % (infile, msg, errno)
  sys.exit(1)

# 内容を読み込む
try:
  try:
    text = f_in.read()
  except IOError, (errno, msg):
    print >> sys.stderr, 'Error: cannot read file "%s": %s' % (infile, msg)
    sys.exit(1)
finally:
  f_in.close()

# エンコーディング検出を実行
encoding = simple_chardet(text)

# 結果の表示
if encoding:
  print encoding
else:
  print 'other encoding'
