#coding:utf-8
#<field name="cited_list" type="string" indexed="true" stored="true" multiValued="true"/>
#cite_listフィールドの値を消去(アトミックアップデートで)
require '/opt/atomic_update/create_atomic.rb'
require '/opt/solr_test_server/sort_hanketubun.rb'
require 'fileutils'

F_PATH="/opt/citation.csv"
FILE_ROOT = '/opt/atomic_update/meta_data/tmp/'
FileUtils.mkdir_p(FILE_ROOT)
field = "cite_list"

#main
sort_hanketubun = Sort_Hanketubun.new()
file = open(F_PATH,"r")
file.each_line{|l|
	citeId,citedId = l.chomp.split(",")
	citeAtomic = Atomic_Update.new()
	citeAtomic.set_unique(citeId)
	citeAtomic.setDeleteUpdate(field)
	path = sort_hanketubun.file_analysis(citeId,FILE_ROOT)
	dest = path+citeId+".xml"
	citeAtomic.create_atomic_file(dest)
}

