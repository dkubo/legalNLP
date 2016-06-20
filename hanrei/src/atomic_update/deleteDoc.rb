#coding:utf-8
#アトミックアップデート形式のファイルを作成するクラス

class DeleteDoc
	def initialize()
		@del = "<delete>\n"
	end
	def set_id(id)
		@del += "<id>"+id+"</id>\n"
	end
	#Solr登録データ更新(引数：更新したい元ファイルのパス,書き込みたい内容すべて(更新前の分も含む))
	def create_file(file_path)
		File.open(file_path,'w') do |io|
			@del += "</delete>"
			io.write @del
		end
	end
end
