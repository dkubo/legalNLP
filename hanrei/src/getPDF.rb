#coding:utf-8

#require 'saikousai_scraping'
require 'fileutils'

URL_PATH = ARGV[0]
PDF_PATH = ARGV[1]

#####################################
#				詳細データ出力先分類
#####################################
def classify_dir(fname,root_path)
	dir_path=""
	if fname.length == 5 then
		dir_path=root_path+fname[0]+"/"+fname[1]+"/"+fname[2]+"/"
	elsif fname.length > 5 then
		dir_path=root_path+fname[0..(fname.length-5).to_i]+"/"+fname[(fname.length-4).to_i]+"/"+fname[(fname.length-3).to_i]+"/"
	elsif fname.length == 4 then
		dir_path=root_path+"0/"+fname[0]+"/"+fname[1]+"/"
	elsif fname.length == 3 then
		dir_path=root_path+"0/0/"+fname[0]+"/"		
	else
		dir_path=root_path+"0/0/0/"		
	end	
	FileUtils.mkdir_p(dir_path)
	return dir_path
end
#####################################################################
#								main
#####################################################################
file=open(URL_PATH,'r')
file.each_line{|l|
	out_path=""
	$url=l.chomp
	id = l.split('/')[-1][1..5]
	$out_path = classify_dir(id,PDF_PATH)
#	system('wget -4 ${l} -P ${out_path}')
`wget -4 #$url -P #$out_path`
}





