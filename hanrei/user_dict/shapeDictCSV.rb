#coding:utf-8

#mecab形式へ変換

#PATH='/home/daiki/デスクトップ/hanrei/user_dict/downloaded'
#PATH='/home/daiki/デスクトップ/hanrei/user_dict/synonym.csv'
PATH='/home/daiki/デスクトップ/hanrei/user_dict/userDict.csv'

def conv(word)
	return "#{word},,,1,名詞,一般,*,*,*,*,*,*,*"


end
array=[]
f=open(PATH,'r')
f.each_line{|l|
	puts conv(l.chomp)
#	array.push(l.chomp)
#	array=l.chomp.split(',')
#	for i in array do
#		puts i
#	end
#	if /（(昭和|平成).*）$/ =~ l.chomp
#		hourei=$`
#	end
#	puts hourei
}
#puts array.length
#array.uniq!
#for i in array do
#	puts i
#end

