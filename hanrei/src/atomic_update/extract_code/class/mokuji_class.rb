#coding:utf-8

#目次生成クラス
class Index_Gen
	require "pp"
	require 'moji'
	def initialize()
		@mokuji = ''
	end

	#全角空白と半角空白を全て消去して主文の目次開始を探す
	def search_syubun(line,syubun_frg)
		match_line = line.delete("\s　").chomp
		if /^主文/ =~ match_line.delete("○（）()")
			@mokuji += '主文'+"\n"		#「主文」の文言は、主文で統一
			syubun_frg = 1
		end
		return syubun_frg
	end

	#全角空白と半角空白を全て消去して事実及び理由の目次開始を探す
	def search_riyu(line,riyu_frg)
		match_line = line.delete("\s　").chomp
		if(/^(事実及び理由|理由１|事実および理由|理由第１|理由|事実|第１|（犯行に至る経緯）|理由の要旨|事実及び争点|仮処分命令申請書)/ =~ match_line.delete("○"))
			if $& == '第１'
				@mokuji += match_line
			else
				@mokuji += $&+"\n"			#「事実及び理由」部はそれぞれの文言を使用(但し空白は消去)
			end
			first_pattern = ''
			second_pattern = ''
			riyu_frg = 1
		end
		return riyu_frg
	end

	#全角空白と半角空白を全て消去して事実及び理由の目次を探す
	def get_riyu_index(line,first_pattern,second_pattern,pattern,kaisou_one_list,kaisou_two_list,last_frg)
		match_line = line.lstrip.gsub(/^　*/,'')		#左端の空白消去
		if(/^(事実及び理由|理由１|事実および理由|（犯行に至る経緯）|理由第１|理由|事実|理由の要旨|事実及び争点|仮処分命令申請書)\n/ =~ match_line.delete("○"))
			@mokuji += $&+"\n"			#「事実及び理由」部はそれぞれの文言を使用(但し空白は消去)
		end
		if(/^(（別紙）|（参考)|引換給付義務一覧表/ =~ match_line)
			@mokuji += $&+"\n"
			last_frg = 1
		end
		if(/^((（|〔|【)(原告|被告|原告ら|被告ら)の主張(）|〕|】))/ =~ match_line or /^((\(|（)罪となるべき事実|(甲|乙)事件について|事実認定の補足説明|証拠の標目|法令の適用|犯罪事実|弁護人の主張に対する判断|量刑の理由(\)|）))/ =~ match_line)
			@mokuji += $&+"\n"
		end
		if first_pattern == '' and second_pattern == ''
			#第一階層目のパターンを探す(左端の空白を消去して)
			if /^第(1|１|一)(\s|　)/ =~ match_line
				kaisou_num = $&
				first_pattern = '第([1-9１-９]|[一二三四五六七八九十])'
				@mokuji += match_line
				pattern = 1
				########################################
				#					階層番号保存
				########################################
				if /[一二三四五六七八九十]/ =~ kaisou_num
					kansuji = $&
					kaisou_one_num = kan_to_han(kansuji)
					kaisou_one_list.push(kaisou_one_num)
				elsif /[1-9１-９]/ =~ kaisou_num
					suji = $&
					kaisou_one_num = to_han(suji)
					kaisou_one_list.push(kaisou_one_num)
				end
			elsif /^1(\s|　)/ =~ match_line
				kaisou_num = $&
				first_pattern = '([1-9])'
				@mokuji += match_line
				pattern = 2
				#階層番号保存
				kaisou_one_list.push(kaisou_num)
			elsif /^１(\s|　)/ =~ match_line
				kaisou_num = $&
				first_pattern = '([１-９])'
				@mokuji += match_line
				pattern = 3
				#階層番号保存
				kaisou_one_num = to_han(kaisou_num)
				kaisou_one_list.push(kaisou_one_num)
			elsif /^一(\s|　)/ =~ match_line
				kaisou_num = $&
				first_pattern = '([一二三四五六七八九十])'
				@mokuji += match_line
				pattern = 4
				#階層番号保存
				kaisou_one_num = kan_to_han(kaisou_num)
				kaisou_one_list.push(kaisou_one_num)
			end
		elsif first_pattern != '' and second_pattern == ''
			#第二階層目のパターンを探す
			if /^第(1|１|一)(\s|　)/ =~ match_line and pattern != 1
				kaisou_num = $&
				first_pattern = '第([1-9１-９]|[一二三四五六七八九十])'
				@mokuji += match_line
				#階層番号保存
				#漢数字→英数字
				if /[一二三四五六七八九十]/ =~ kaisou_num
					kansuji = $&
					kaisou_one_num = kan_to_han(kansuji)
				elsif /[1-9１-９]/ =~ kaisou_num
					kaisou_one_num = to_han($&)
				end
				kaisou_one_list.push(kaisou_one_num)
			elsif /^1(\s|　)/ =~ match_line and pattern != 2
				kaisou_num = $&
				second_pattern = '([1-9])'
				@mokuji += match_line
				#階層番号保存
				kaisou_two_num = to_han(kaisou_num)
				kaisou_two_list.push(kaisou_two_num)
			elsif /^１(\s|　)/ =~ match_line and pattern != 3
				kaisou_num = $&
				second_pattern = '([１-９])'
				@mokuji += match_line
				#階層番号保存
				kaisou_two_num = to_han(kaisou_num)
				kaisou_two_list.push(kaisou_two_num)
			elsif /^一(\s|　)/ =~ match_line and pattern != 4
				kaisou_num = $&
				second_pattern = '([一二三四五六七八九十])'
				@mokuji += match_line
				#階層番号保存
				#漢数字→英数字
				kaisou_two_num = kan_to_han(kaisou_num)
				kaisou_two_list.push(kaisou_two_num)
			elsif /^(\(|（)(1|１)(\)|）)(\s|　)/ =~ match_line
				kaisou_num = $&
				#second_pattern == '(\(|（)([1-9１-９])(\)|）|\)ア|）ア)'
				second_pattern == '(\(|（)([1-9１-９])(\)|）))'
				@mokuji += match_line
				#階層番号保存
				if /[1-9１-９]/ =~ kaisou_num
					kaisou_two_num = to_han($&)
				end
					kaisou_two_list.push(kaisou_two_num)
			elsif /^(\(|（)一(\)|）)(\s|　)/ =~ match_line
				kaisou_num = $&
				second_pattern == '(\(|（)([一二三四五六七八九十])(\)|）))'
				@mokuji += match_line
				#階層番号保存
				if /[一二三四五六七八九十]/ =~ kaisou_num
					kansuji = $&
					kaisou_two_num = kan_to_han(kansuji)
				end
					kaisou_two_list.push(kaisou_two_num)
			end
			if /^#{first_pattern}(\s|　|、)/ =~ match_line
				kaisou_num = $&
				@mokuji += match_line
				#階層番号保存
				if /[一二三四五六七八九十]/ =~ kaisou_num
					kansuji = $&
					kaisou_one_num = kan_to_han(kansuji)
				elsif /[1-9１-９]/ =~ kaisou_num
					kaisou_one_num = to_han($&)
				end
					kaisou_one_list.push(kaisou_one_num)
			end
		#第一階層と第二階層のパターンが見つかった場合
		elsif first_pattern != '' and second_pattern != ''
			if /^#{first_pattern}(\s|　|、)/ =~ match_line
				kaisou_num = $&
				@mokuji += match_line
				#階層番号保存
				if /[一二三四五六七八九十]/ =~ kaisou_num
					kansuji = $&
					kaisou_one_num = kan_to_han(kansuji)
				elsif /[1-9１-９]/ =~ kaisou_num
					kaisou_one_num = to_han($&)
				end
					kaisou_one_list.push(kaisou_one_num)
			elsif /^#{second_pattern}(\s|　|、)/ =~ match_line
				kaisou_num = $&
				@mokuji += match_line
				#階層番号保存
				if /[一二三四五六七八九十]/ =~ kaisou_num
					kansuji = $&
					kaisou_two_num = kan_to_han(kansuji)
				elsif /[1-9１-９]/ =~ kaisou_num
					kaisou_two_num = to_han($&)
				end
					kaisou_two_list.push(kaisou_two_num)
			end
		end
		return first_pattern,second_pattern,pattern,@mokuji,kaisou_one_list,kaisou_two_list,last_frg
	end
	#kaisou_third_pattern = '\(([1-9]|[１-９]|\([\p{Han}]\)|\([\p{Hiragana}]\)|〔.*〕)\)'
	#別紙は目次に入れない(加えて別紙は構造化されてないケースが多い)

	#全角数字→半角数字
	def to_han(zenkaku)
		return Moji.zen_to_han(zenkaku,Moji::ZEN_NUMBER).to_i
	end

	def kan_to_han(kansuji)
		hash = {"一" => 1,"二" => 2,"三" => 3,"四" => 4,"五" => 5,"六" => 6,"七" => 7,"八" => 8,"九" => 9}
		hansuji = hash[kansuji.to_s.delete("\s　")]
		return hansuji
	end
end

