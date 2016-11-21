#coding:utf-8

a ="久保大輝(以降、「私」と呼ぶ。)はカレー(辛いもの（特にインドカレーです。）に限ります。) が大好きです。また、２３日（以降、昨日と呼ぶ。）に雨が降ったとき、傘を忘れてきました。そして、は平成５年１２月２６日生まれである。"
puts a

res = []
sensp = []
merge = ""
open_cnt = 0
close_cnt = 0
res = a.split("。")
# for i in res
# 	puts i
# end

for part in res do
	puts part
	open_cnt += part.count("(（")
	close_cnt += part.count(")）")
	puts open_cnt , close_cnt

	if (open_cnt > close_cnt) then
		merge += part + "。"
	else
		merge += part
		sensp.push(merge)
		merge = ""
	end
end

# for i in sensp
#	puts "---------------------------------"
#	puts i
# end

