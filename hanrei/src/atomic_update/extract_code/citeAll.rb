#coding:utf-8
require '/opt/atomic_update/create_atomic.rb'
require '/opt/solr_test_server/sort_hanketubun.rb'

CITE_PATH = ARGV[0]
REGIROOT = ARGV[1]
#CITE_PATH='/opt/citation.csv'
#REGIROOT='/opt/atomic_update/meta_data/other/citeAll/'
hash = {}
file = open(CITE_PATH,'r')
file.each_line{|l|
	citeId,citedSaibanNum = l.chomp.split(',')	
	hash[citeId] = []
}

file = open(CITE_PATH,'r')
file.each_line{|l|
	citeId,citedSaibanNum = l.chomp.split(',')	
	hash[citeId].push(citedSaibanNum)
}

sort_hanketubun = Sort_Hanketubun.new()
for id,v in hash do
	citeAll_atomic = Atomic_Update.new()
	citeAll_atomic.set_unique(id)
	p "---------------------------------"
	p id
	v = v.uniq		#重複消去
	for citeNum in v do
		citeAll_atomic.set_update('citeAll',citeNum)
#		citeAll_atomic.setDeleteUpdate('citeAll')		#デリートする用
	end
	path = sort_hanketubun.file_analysis(id,REGIROOT)
	dest = path+id+".xml"
	citeAll_atomic.create_atomic_file(dest)
end

