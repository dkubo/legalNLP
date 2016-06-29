#coding:utf-8
require 'fileutils'

FILE_ROOT = '/opt/atomic_update/meta_data/showa/ref/'
PATTERN = '**/**/*.xml'
OUT = '/opt/atomic_update/meta_data/showa/searchRef/'
Dir.chdir(FILE_ROOT)
Dir.glob(PATTERN) do |file|
	total = ''
	tmp = file.split('/')
	dir = OUT+tmp[0]+'/'+tmp[1]
	FileUtils.mkdir_p(dir)
	f = open(file,'r')
	f.each_line{|l|
		total+=l
	}
	total = total.gsub('ref','searchRef')
	#ファイル出力
	File.open(OUT+file,"a") do |file|
		file.puts(total)
	end
end
