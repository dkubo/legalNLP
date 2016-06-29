#coding:utf-8
cnt=1
Dir.glob('./text/**/**/**/*').each do |f|
	if /\.csv/ =~ f
		$fpath = f.chomp
		tid=f.split('/')[-1][0..4]
		puts tid
		puts "cnt:"+cnt.to_s
		cnt+=1
	end
end

