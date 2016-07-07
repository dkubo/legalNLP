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


xlsx = readxlsheet(DataFrame, JDMWE_PATH, "Sheet1", colnames=[:A, :B, :C, :D, :E, :F, :G, :H])
println(xlsx)
#
#open(BCCWJ_PATH) do f
#	for line in eachline(f)
#		println(line)
#	end
#end

