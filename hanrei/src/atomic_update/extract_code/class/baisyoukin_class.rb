#coding:utf-8
require '/opt/atomic_update/extract_code/class/zen_to_i/zen_to_i'
require 'nkf'

#########################################################################################
#「。」で主文を区切てマッチングさせる（1月以降）
#例：～円の後方に「換算」というワードが入って入れば、それは無視
#例：～円の前方に、「～のいずれも」というワードがあれば、複数人が支払うことを考慮する
#例：～円の後方に、「内金」というワードがあれば、それは無視
#########################################################################################

###########################################################################	
#						主文から賠償額抽出→漢数字は変換→合計額計算クラス
###########################################################################	
class Calc_Baisyou
	def initialize()
		puts "calc_start!"
	end
	###########################################################################	
	#						億の位、万の位、千の位を分ける
	###########################################################################	
	def split_digit(digit)
		oku = ''
		man = ''
		sen = ''
		#まず、万で分割
		if /億/ =~ digit
			oku = $`
			man = $'
			oku = oku.zen_to_i.to_s		#半角へ変換
			if /万/ =~ $'
				man = $`
				sen = $'
			end
			man = man.zen_to_i.to_s
			sen = sen.zen_to_i.to_s
			#桁数整理
			if sen.length < 4# and sen.length != 0
				sen_lack = 4 - sen.length.to_i-1
				for zero in 0..sen_lack do
					sen = "0"+sen
				end
			end
			#桁数整理
			if oku != '' and man.length < 4
				man_lack = 4 - man.length.to_i-1
				for zero in 0..man_lack do
					man = "0"+man
				end
			end
			digit = oku+man+sen
		end
		return digit
	end
	###########################################################################	
	#							賠償金の合計額計算
	###########################################################################	
	def calc_total(baisyou_list)
		total = 0
		for baisyou in baisyou_list do
			total += baisyou.to_i
		end
		return total.to_s
	end
	###########################################################################	
	#							合計額の万の位以下は切り捨て関数
	###########################################################################	
	def calc_totalman(total)
		total = total.to_s.delete("円")
		get_digit = total.length - 4		#get_digit:取得する桁数
		if get_digit > 0
			total_man = total[0,get_digit]+'万円'
			total_other = ''
		else		#total_other:賠償額が1万以下のもの
			total_other = total
			total_man = ''
		end
		return total_man,total_other
	end
	###########################################################################	
	#							賠償額抽出
	###########################################################################	
	def calc_baisyou(syubun)
		tmp = []
		tmp2 = []
		baisyou_list = []
		#※注意：tmp,tmp2は配列の中に配列として格納([[10万円],[20万円],[40万円]])
#		tmp = syubun.delete("\n").scan(/((?!税額)|(?!内金))([０-９百千万億.,，、]+円)/)		#前方に税額がくるのは無視
		tmp = syubun.delete("\n").scan(/(?!内金)([０-９百千万億兆.,，、]+円)/)		#前方に税額がくるのは無視
#		tmp2 = syubun.delete("\n").scan(/(?!税額)([〇一二三四五六七八九十百千万億兆.,，、]+円)/)
		tmp2 = syubun.delete("\n").scan(/(?!内金)([〇一二三四五六七八九十百千万億兆.,，、]+円)/)

		#tmp:アラビア数字
		for i in tmp do
			a = ''
			for a in i do
			 if a == "万円"
					next
				else
					hankaku = NKF.nkf('-m0Z1 -w', a.delete(".,，、円"))		#半角に変換
					digit = split_digit(hankaku)				#整型(1億120万1022円→101201022)
					baisyou_list.push(digit)
				end
			end
		end
		#tmp2:漢数字
		for k in tmp2 do
			for b in k do
				if b == "万円"
					next
				else
					digit =	split_digit(b.delete(".,，、円"))
					baisyou_list.push(digit)
				end
			end
		end
		total = calc_total(baisyou_list)		#賠償金合計計算
		total_man,total_other = calc_totalman(total)		#合計額の万の位以下は無視
		return total,total_man,total_other
	end
end

###########################################################################	
#						算出した賠償額をファセット情報ごとに分類するクラス
###########################################################################	
class Facet_Bunruri
	def initialize()
		puts "bunrui_start!"
	end

	###########################################################################	
	#						該当する親/子ファセットを返す関数
	###########################################################################
	def calc_facet(total_man,total_other)		#total_man:賠償額が一万円以上のものの万以上の位、total_other:賠償額が一万円以下のもの
		if total_other == ""	#賠償額が一万円以上
			digit = total_man.delete("億万円").length
			if digit == 1		#1桁の場合(1～9万円)
				parent_facet = "1～9万円台"
				child_facet = total_man+"台"
			elsif digit == 2		#2桁の場合(10～99万円)
#				parent_facet = total_man[0,1]+"0～"+total_man[0,1]+"9万円"
				parent_facet = "10～99万円台"
				child_facet = total_man[0,1]+"0万円台"
			elsif digit == 3		#3桁の場合(100～999万円)
#				parent_facet = total_man[0,1]+"00～"+total_man[0,1]+"99万円"
				parent_facet = "100～999万円台"
				child_facet = total_man[0,1]+"00万円台"
			elsif digit == 4		#4桁の場合(1000～9999万円)
#				parent_facet = total_man[0,1]+"000～"+total_man[0,1]+"999万円"
				parent_facet = "1000～9999万円台"
				child_facet = total_man[0,1]+"000万円台"
			elsif digit == 5		#5桁の場合(1～9億円)
				oku = total_man[0,1]
				senman = total_man[1,1]
				parent_facet = "1～9億円台"
				if senman.to_i >= 5		#1億5000万円以上の場合
					senman = "5"
					child_facet = oku+"億"+senman+"000万円～"+oku+"億9999万円"
				else
					senman = "0"
					child_facet = oku+"億円～"+oku+"億4999万円"
				end
			elsif digit == 6		#6桁の場合(10～99億円)
#				parent_facet = total_man[0,1]+"0～"+total_man[0,1]+"9億円"
				parent_facet = "10～99億円台"
				oku = total_man[0,2]
				senman = total_man[2,1]
				if senman.to_i >= 5		#1億5000万円以上の場合
					senman = "5"
					child_facet = oku+"億"+senman+"000万円～"+oku+"億9999万円"
				else
					senman = "0"
					child_facet = oku+"億円～"+oku+"億4999万円"
				end
			elsif digit >= 7		#賠償額が100億円以上の場合、子ファセットなし
				child_facet = ''
				parent_facet = '100億円以上'
			end
		else									#賠償額が一万円以下の場合、子ファセットなし
#			puts total_other
			if total_other == "0"
				child_facet = ''
				parent_facet = ''
			else
				child_facet = ''
				parent_facet = '1～9999円'
			end
		end
		return parent_facet,child_facet
	end
end
