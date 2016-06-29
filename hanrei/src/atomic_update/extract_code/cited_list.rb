#coding:utf-8
#<field name="cited_list" type="string" indexed="true" stored="true" multiValued="true"/>

require '/opt/atomic_update/create_atomic.rb'
require '/opt/solr_test_server/sort_hanketubun.rb'
require 'fileutils'

F_PATH = ARGV[0]
FILE_ROOT = ARGV[1]
#F_PATH="/opt/cite_cited.csv"
#FILE_ROOT = '/opt/atomic_update/meta_data'

#main
sort_hanketubun = Sort_Hanketubun.new()
citedHash = {}		#key:引用先裁判番号、値；引用元裁判番号
root = FILE_ROOT+"/cited_list/"
file = open(F_PATH,"r")
file.each_line{|l|
	citeId,citedId = l.chomp.split(",")
	citedHash[citedId] = []		#初期化
}
file = open(F_PATH,"r")
file.each_line{|l|
	citeId,citedId = l.chomp.split(",")
	citedHash[citedId].push(citeId)
}
#この段階で、citedHashには、全ての引用・非引用が入っている状態(値は配列で入っている)
for citedId,citeIds in citedHash do
	citedAtomic = Atomic_Update.new()
	citedAtomic.set_unique(citedId)
	for citeId in citeIds do
		citedAtomic.set_update("cited_list",citeId)
	end
	FileUtils.mkdir_p(root)
	path = sort_hanketubun.file_analysis(citedId,root)
	dest = path+citedId+".xml"
	citedAtomic.create_atomic_file(dest)
end

