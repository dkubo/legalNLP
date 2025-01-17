#coding:utf-8
#法条階層ファイルを読み込んで、木構造に割り当てる
#第三階層まで対応
#path:階層元ファイル
#ハッシュを返す

class Create_Tree
	def initialize()
		@kaisou = []
		@big = {}				#第一階層
		@middle = {}		#第二階層
		@small = {}			#第三階層
		@tree = {}
		@tree2 = {}
		@sml_tree = Hash.new( {} )	#二次元ハッシュ初期化
		@pre_big = ''
		@pre_mid = ''
		@total = 0
		@big_cnt = 0
		@mid_cnt = 0
		@sml_cnt = 0
	end
	def create(path)
	#ファイル読み込み
		file = open(path,'r')
		file.each_line{|l|
			@kaisou = l.chomp.split(',')
		#第四階層以上を保持している場合は、それらを破棄
			k = @kaisou.length - 3
			if k >= 1 then
				for i in -k..-1 do
					@kaisou.delete_at(i)
				end
			end
#			puts @kaisou
		#第3階層を末尾に持ってくる
			tmp = @kaisou[0]
			@kaisou.shift
			@kaisou.push(tmp)

			if @pre_big != @kaisou[0] and @total != 0 then
				@big_cnt += 1
			end
			if @pre_mid != @kaisou[1] and @total != 0 then
				@mid_cnt += 1
#				@sml_cnt = 0
			end
			@big[@kaisou[0]] = @big_cnt
			@middle[@kaisou[1]] = @mid_cnt
			@small[@kaisou[2]] = @sml_cnt
			@sml_cnt += 1
			@total += 1
			@pre_big = @kaisou[0]
			@pre_mid = @kaisou[1]
		}
	#辞書格納
		@tree = {@big => @middle}
		@tree2 = {@middle => @small}

#		for h in @tree do
#			p h[0]["公法"]		#→インデックスは0
#			p h[1]["憲法"]		#→インデックスは0
#		end
#		for h in @tree2 do
#			p h[0]["憲法"]				#→インデックスは0
#			p h[0]["医療・公衆衛生"]		#→インデックスは23
#		end

		return @tree,@tree2
	end
end



