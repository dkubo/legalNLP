#coding:utf-8
#アトミックアップデート形式のファイルを作成するクラス

class Atomic_Update
	def initialize(boost="1.0")
		@atomic = "<add><doc boost=\""+boost.to_s+"\">"
	end
	def plus_data(field_n,field_v,update_type)
		@atomic += "<field name=\""+field_n+"\" update=\""+update_type+"\">"+field_v+"</field>"
	end
	def set_unique(id)
		@atomic += "<field name=\"id\">"+id+"</field>"
	end
	#multiValued="false"のフィールドに対する更新
	def set_update(field_n,field_v)
		update_type = 'set'
		plus_data(field_n,field_v,update_type)
	end
	#multiValued="true"のフィールドに対する更新
	def add_update(field_n,field_v)
		update_type = 'add'
		plus_data(field_n,field_v,update_type)
	end
	#既存のフィールドを消去
	def setDeleteUpdate(field_n)
		@atomic += "<field name=\""+field_n+"\" update=\"set\" null=\"true\" />"
	end
	#Solr登録データ更新(引数：更新したい元ファイルのパス,書き込みたい内容すべて(更新前の分も含む))
	def create_atomic_file(file_path)
		File.open(file_path,'w') do |io|
			@atomic += '</doc></add>'
			io.write @atomic
		end
	end
end
