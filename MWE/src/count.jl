#coding:utf-8

using ExcelReaders
using DataFrames

"""
JDMWEのエントリとBCCWJのCORE_SUWとのマッチング
Daiki Kubo
2016/7/8

"""

const BCCWJ_PATH="../data/core_SUW.txt"
const JDMWE_PATH="../data/JDMWE_idiom v1.3 20121215.xlsx"


#jdmwe = readxlsheet(DataFrame, JDMWE_PATH, "Sheet1", colnames=[:A, :B, :C, :D, :E, :F, :G, :H])
#println(jdmwe)


#bccwj = readtable(BCCWJ_PATH, separator = '\t', names=map(symbol,[:register, :sample_id, :chara_start_posi, :chara_end_posi, :order_id, :occur_start_posi, 
#																																	:occur_end_posi, :fixed_frg, :variable_frg, :BI_label, :lemma_table_id, :lemma_id, :lemma, 
#																																	:lForm, :subLemma, :wType, :pos, :cType, :cForm, :formBase, :usage, :orthBase, :orthToken,
#																																	:originalText ,:pronToken]))
bccwj = readtable(BCCWJ_PATH, separator='\t', header=false, names=[:register, :sample_id, :chara_start_posi, :chara_end_posi, :order_id, :occur_start_posi, 
																																		:occur_end_posi, :fixed_frg, :variable_frg, :BI_label, :lemma_table_id, :lemma_id, :lemma, 
																																		:lForm, :subLemma, :wType, :pos, :cType, :cForm, :formBase, :usage, :orthBase, :orthToken,
																																		:originalText ,:pronToken])
println(bccwj)

