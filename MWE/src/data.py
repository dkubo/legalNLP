#coding:utf-8

import re
import pandas as pd

def getsheet(dicnum):
	if dicnum in ["2", "3", "6", "7", "17"]:
		sheet = "sheet1"
	else:
		sheet = "Sheet1"
	return sheet

# JDMWE読込
def loadMWE(mwe_path, dicnum):
	sheet = getsheet(dicnum)
	df_B = pd.read_excel(mwe_path, sheetname=sheet, parse_cols="C")
	if dicnum == "18":
		df_F = pd.read_excel(mwe_path, sheetname=sheet, parse_cols="G")
		df_B = df_B[0:-1]
		df_F = df_F[0:-1]
	else:
		df_F = pd.read_excel(mwe_path, sheetname=sheet, parse_cols="F")

	return df_B, df_F

# parse dict
def parse_dict(mwe_path, dicnum):
	df_B, df_F = loadMWE(mwe_path, dicnum)
	for mwe_B, mwe_F in zip(df_B.values, df_F.values):
		# print "----------------------"
		matchOB = re.match(r"(\*)", mwe_F[0])
		# 内部修飾が先頭以外にあるもの
		if matchOB:
			# print mwe_B[0], mwe_F[0]
			


		else:
			mwe_B = re.sub(r"(-|_)", "", mwe_B[0])
			mwe_reg = re.compile(mwe_B)
			# matchOB = mwe_reg.match(text)
			print mwe_reg


