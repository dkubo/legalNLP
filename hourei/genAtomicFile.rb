#coding:utf-8

#テキストデータとインデックスデータから、アトミックファイル作成
###################################################
#					法令の階層(例：民事訴訟法)
###################################################
#改正沿革(あるやつとないやつ有)
#法令名(法令番号)
#前文,制定文
#(本則)
	#第一編　総則
		#第一章 通則(第一条-第三条)
		#第二章 裁判所
			#第一節 日本の裁判所の管轄権(第三条の二-第三条の十二)
			#第二節 管轄(第四条-第二十二条)
	#.....
#(附則)
	#第一条
	#第一条
	#第一条
	#第二条
	#.....
###################################################


###################################################
#								DB格納予定
###################################################
#id：id
#法令名：houreiName
#法令番号：houreiNum
#条文全て：jobunAll
#各条項：joHash(key:～条,value:条文),(multivalued=true)
#目次：index
###################################################

require '/opt/atomic_update/create_atomic.rb'
require '/opt/atomic_update/extract_code/class/zen_to_i/zen_to_i'

ROOT="/opt/e-gov/data/"
REGI_ROOT="/opt/e-gov/atomicUpdate/"
TEXT_PATTERN="*.txt"
ALLOT_GENGO={"慶応"=>"0","明治"=>"1","大正"=>"2","昭和"=>"3","平成"=>"4"}
ALLOT_ORG={"法律"									=>"00",
					 "農林水産省"						=>"01",
					 "政令"									=>"02",
					 "総理府"								=>"03",
					 "郵政省"								=>"04",
					 "自治省"								=>"05",
					 "文部科学省"						=>"06",
					 "勅令"									=>"07",
					 "文部省"								=>"08",
					 "国土交通省"						=>"09",
					 "総務省"								=>"10",
					 "法務省"								=>"11",
					 "外務省"								=>"12",
					 "財務省"								=>"13",
					 "厚生労働省"						=>"14",
					 "環境省"								=>"15",
					 "経済産業省"						=>"16",
					 "建設省"								=>"17",
					 "内閣府"								=>"18",
					 "司法省"								=>"19",
					 "大蔵省"								=>"20",
					 "厚生省"								=>"21",
					 "逓信省"								=>"22",
					 "労働省"								=>"23",
					 "国家公安委員会"				=>"24",
					 "通商産業省"						=>"25",
					 "海上保安庁"						=>"26",
					 "人事院"								=>"27",
					 "第一復員省"						=>"28",
					 "第二復員省"						=>"29",
					 "農林省"								=>"30",
					 "公正取引委員会"				=>"31",
					 "文化財保護委員会"				=>"32",
					 "会計検査院"						=>"33",
					 "法務庁"								=>"34",
					 "内務省"								=>"35",
					 "閣令"									=>"36",
					 "原子力規制委員会"				=>"37",
					 "太政官"								=>"38",
					 "運輸通信省"						=>"39",
					 "外資委員会"						=>"40",
					 "首都圏整備委員会"				=>"41",
					 "法務府"								=>"42",
					 "防衛省"								=>"43",
					 "電波監理委員会"				=>"44",
					 "農商務省"							=>"45",
					 "復興庁"								=>"46",
					 "公安審査委員会"				=>"47",
					 "金融再生委員会"				=>"48",
					 "中央労働委員会"				=>"49",
					 "商工省"								=>"50",
					 "鉄道省"								=>"51",
					 "公害等調整委員会"				=>"52",
					 "日本ユネスコ国内委員会"	=>"53",
					 "憲法"									=>"54",
					 "地方財政委員会"				=>"55",
					 "運輸安全委員会"				=>"56",
					 "公認会計士管理委員会"		=>"57",
					 "日本学術会議"					=>"58",
					 "総理庁"								=>"59",
					 "土地調整委員会"				=>"60",
					 "司法試験管理委員会"			=>"61",
					 "運輸省"								=>"62",
					 "電気通信省"						=>"63",
					 "経済安定本部"					=>"64"
}

###################################################
#						id割り当て関数
###################################################
def allotId(houreiNum)
	id = ''
	tmp = houreiNum
#	p "before"+houreiNum
	for k,v in ALLOT_GENGO do
		if /#{k}/ =~ houreiNum
			houreiNum = houreiNum.gsub($&,v)
			break
		end
	end
	for k,v in ALLOT_ORG do
		if /#{k}/ =~ houreiNum
			houreiNum = houreiNum.gsub($&,v)
		end
	end
	houreiNum = houreiNum.gsub(/元年/,"00")
	houreiNum = houreiNum.zen_to_i
	id = houreiNum.scan(/[0-9]/)
	id = id.join
	return id
end

Dir.chdir(ROOT)
Dir.glob("index/*.txt") do |i_file|
	########################################
	#						変数初期化
	########################################
	cnt = 0
	index = ''
	houreiName = ''
	houreiNum = ''
	jobunAll = ''
	joHash = {}
	jo = ''
	jo_frg = 0
	########################################
	index_f = open(i_file,"r")
	houreiName = i_file.split("/")[1].delete(".txt")
	index_f.each_line{|l|
		if cnt == 1 then
			houreiNum = l.chomp.delete("()（）")
		else
			index += l
		end
		cnt += 1
	}
	jobun_f = open(ROOT+"jobun/"+houreiName+".txt","r")
	jobun_f.each_line{|l|
		if /附則/ =~ l.chomp.lstrip.delete("\s　\t")
			jo_frg = 0
			break
		elsif /^(第[0-9０-９〇一二三四五六七八九十百千]{1,6}条の[0-9０-９〇一二三四五六七八九十百千]{1,2}|第[0-9０-９〇一二三四五六七八九十百千]{1,6}条)/ =~ l.chomp then
			jo = $&
			joHash[jo] = ''
			jo_frg = 1
		elsif jo_frg == 1 and l != "\n" then
			joHash[jo] += l.to_s
		end
	}
	text_f = open("text/"+houreiName+".txt","r")
	text_f.each_line{|t|
		jobunAll += t
	}
	id = allotId(houreiNum)
	puts id
	puts houreiName
###################################################
#							アトミックファイル作成
###################################################
	hourei_atomic = Atomic_Update.new()
	hourei_atomic.set_unique(id)
	hourei_atomic.set_update("houreiName",houreiName)
	hourei_atomic.set_update("houreiNum",houreiNum)
	hourei_atomic.set_update("index",index)
	hourei_atomic.set_update("jobunAll",jobunAll)
	for jo,jobun in joHash do
		joNum = jo.zen_to_i
		hourei_atomic.set_update(joNum+"_",jobun)
	end
	dest = REGI_ROOT+id+".xml"
	hourei_atomic.create_atomic_file(dest)
end


