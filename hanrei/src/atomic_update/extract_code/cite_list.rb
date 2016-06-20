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
citeHash = {}		#key:引用先裁判番号、値；引用元裁判番号
root = FILE_ROOT+"/cite_list/"
file = open(F_PATH,"r")
file.each_line{|l|
	citeId,citedId = l.chomp.split(",")
	citeHash[citeId] = []		#配列で初期化
}
file = open(F_PATH,"r")
file.each_line{|l|
	citeId,citedId = l.chomp.split(",")
	citeHash[citeId].push(citedId)		#値をpushする
}
#この段階で、citedHashには、全ての引用・非引用が入っている状態(値は配列で入っている)
for citeId,citedIds in citeHash do
	citeAtomic = Atomic_Update.new()
	citeAtomic.set_unique(citeId)
	for citedId in citedIds do
		citeAtomic.set_update("cite_list",citedId)
	end
	FileUtils.mkdir_p(root)
	path = sort_hanketubun.file_analysis(citeId,root)
	dest = path+citeId+".xml"
	citeAtomic.create_atomic_file(dest)
end
