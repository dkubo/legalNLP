#coding:utf-8
#修正対象フィールド：riyu,mokuji

####################################
# 昭和の判例には、目次がついてない
# 別紙内にあるものは、無視
#どちらにせよ、目次中に、..............がある場合はその目次を消去すればいい
####################################

FILE_ROOT = '/opt/atomic_update/meta_data/other/riyu/08/'
PATTERN = '**/**/*.xml'

Dir.chdir(FILE_ROOT)
Dir.glob(PATTERN) do |file|
	riyu_frg = 0
	exist_mokuji = 0
	total = ''
	riyu = ''
#	p "-----------------------------"
	f = open(file,'r')
	id = file.split('/')[-1].delete('.xml')
	f.each_line{|line|
		total += line
		if /\・{7,100}/ =~ line or /\.{7,100}/ =~ line
			exist_mokuji = 1
		end
		if riyu_frg == 1 then
			riyu += line
		end
		if /<field name="riyu" update="set">/ =~ line then
			riyu_frg = 1
			riyu += $'
		elsif /<\/field><\/doc><\/add>/ =~ line then
			riyu_frg = 0
			riyu += $`
			riyu = riyu.gsub(/<\/field><\/doc><\/add>/,'')
		end
	}
	if exist_mokuji == 1
		puts id
#		puts riyu
	end
end
