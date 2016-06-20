#coding:utf-8
#refをカンマ(，)区切りで分割して登録する


##################################
#			参照法条分割関数
##################################
class Ref_Fix
	def initialize()
		@ref_array = []
	end
	def split_ref(ref)
		buf = ''
		zenpou = ''
		zenpou_doho = ''
		#処理1：「(～につき)」でマッチしたものは「,」で置換
		ref = ref.delete("\s　").gsub(/(\(|（)([0-9０-９]+，[0-9０-９]+，[0-9０-９]+|[0-9０-９]+，[0-9０-９]+|[0-9０-９]+〜[0-9０-９]+|[0-9０-９]+|一、二|一|二|1・2項|1項|2項)につき(\)|）)/,",")
	#処理2：「，」と「,」でそれぞれスプリットする
		tmp2 = ref.gsub("，",",")
		tmp_array = tmp2.split(',')
		for i in tmp_array do
			#処理３：スプリット後、先頭の文字が数字なら、片方のスプリットされた法令名を取得してくる
			if /^([0-9０-９]+)((条|項|條|号|ノ))+/ =~ i
				tmp3 = $2.gsub(/^(\(|（).*(\)|）)/,"")		#先頭にある(～)を消去
				if /^(条|項|條|号|ノ)/ =~ tmp3
					tmp4 = $&
					if /[0-9０-９]+#{tmp4}/ =~ buf
						zenpou = $`
					end
				end
				new_i = zenpou + i
				@ref_array.push(new_i)
			elsif /^同法/ =~ i
				i = $'
				tmp5 = $'.gsub(/^(\(|（).*(\)|）)/,"")		#先頭にある(～)を消去
				tmp6 = tmp5.gsub(/^(施行令|施行規則|附則|)/,"")
				tmp7 = tmp6.gsub(/^(\(|（).*(\)|）)/,"")		#先頭にある(～)を消去
				if /^([0-9０-９]+)((条|項|條|号|ノ))+/ =~ tmp7
					tmp8 = $2
					if /[0-9０-９]+#{tmp8}/ =~ buf
						zenpou_doho = $`
					end
				end
				new_i = zenpou_doho + i
				@ref_array.push(new_i)
			else
				buf = i
				@ref_array.push(i) if i != ""
			end
		end
		return @ref_array
	end
end

