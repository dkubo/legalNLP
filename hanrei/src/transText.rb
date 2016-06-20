#coding:utf-8
require 'fileutils'

TEXT_PATH = ARGV[0]
#####################################
#				詳細データ出力先分類
#####################################
def classify_dir(fname,root_path)
	dir_path=""
	out_path=""
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
	out_path=dir_path+fname+'.csv'
	return out_path
end

#####################################################################
#								main
#####################################################################
tarray=[]
Dir.glob('./text/**/**/**/*').each do |f|
	if /\.csv/ =~ f
		$fpath = f.chomp
		tid=f.split('/')[-1][0..4]
		tarray.push(tid)
	end
end
Dir.glob('./pdf_sources/**/**/**/*').each do |f|
	if /\.pdf/ =~ f
		$fpath = f.chomp
		pid=f.split('/')[-1][1..5]
		if tarray.include?(pid) == false then
			$out_path = classify_dir(pid,TEXT_PATH)
			`java -jar tika-app-1.12.jar -t #$fpath > #$out_path`
			puts $out_path
		end
	end
end

