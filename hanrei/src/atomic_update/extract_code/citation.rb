#coding:utf-8

#判決文中の引用抽出コード
#riyuフィールドを再帰的にオープンしていく
#引用パターンは、http://www5d.biglobe.ne.jp/Jusl/Bunsyo/HanreiHyouji.htmlを参考
#※判決文ごとに引用形式は異なるが、判決文中では形式が統一されている感じ?
#※field name="cite_list" type="string" indexed="true" stored="true" mulitiField="true"でSolrのスキーマに定義してある
#一つの引用に、全てマッチするパターン作る必要がある
#→例：最高裁昭和四四年（オ）四〇五号同四五年\n二月二六日第一小法廷判決・民集二四巻二号一〇九頁
#		→これは一つの判例を引用している
#		→引用に関しては、裁判番号だけ抽出して、リンク先の判決文から、判例集や裁判日、裁判所の情報を取ってくるようにする
require 'nokogiri'
require 'fileutils'
require '/opt/atomic_update/create_atomic.rb'
require '/opt/solr_test_server/sort_hanketubun.rb'
#漢数字をアラビア数字へ変換
require '/opt/atomic_update/extract_code/class/zen_to_i/zen_to_i'

FILE_ROOT = ARGV[0]
OUT_PATH = ARGV[1]
PATTERN = '**/**/*.xml'

#年号の部分が「同」になっている場合、直前の年号を取得する
def shapeCitation(preNengo,citeArray)
	fixCiteArray = []
	for cite in citeArray do
		if /^(昭和|平成)/ =~ cite then
			preNengo = $&
		#年号の部分が「同」になっている場合、直前の年号を取得する
		else
			cite = cite.gsub(/^同/,preNengo)
		end
		fixCiteArray.push(cite) 
	end
	#配列内の重複除去
	fixCiteArray.uniq!
	return preNengo,fixCiteArray
end

################################################################################
#						引用抽出におけるメモ
#	パターン1：最高裁判決本文中の判例の引用,普通の裁判番号のような記述(例：平成13年(行あ)第2401号)
#	パターン2：下級裁が最高裁を引用するパターン,日付+第〜法廷判決(例：昭和47年4月4日第三小法廷判決)
#	その他の引用パターンは、掲載紙によって様々あるが、パターンをつくろうと思えば作れそう
#	→((ジュリスト,法学教室)など,(現代刑事法),(判例タイムズ),(債権管理)・・)
################################################################################
#######################################################################
#						引用文献の判例集パターン抽出におけるメモ
#	一応、SolrDBにも、フィールド「hanrei_syu」としてデータはある(28569件の判例に)
#	→抽出後、参照可能のはず(形式を合わせれば)
#	パターン例：民集10巻5号487頁、裁判集民事195号387頁
#						 集民　第161号1頁、集刑　第88号1頁、刑集　第29巻7号442頁
#	略語参考:http://www.lib.fukushima-u.ac.jp/hanrei/hanrei-1.html
#	略語例：集民→最高裁判所裁判集民事、民集→最高裁判所民事判例集
#######################################################################
def extractCitation(riyu)
	hanreiSyuName="(知的財産例集|不法下民集|行月|行裁月報|行集|行裁例集|一審刑集|第一審刑集|家月|家裁月報|下刑|下刑集|下級刑集|下民|下民集|下級民集|刑月|刑裁月報|刑資|刑集|高刑|高刑集|高裁刑集|高民|高民集|高裁民集|高裁刑特報|交通下民集|民資|民集|無体例集|無体財産例集|労民|労民集|労働民例集|労裁資|労裁集|労働民集|裁時|裁特|審決集|集刑|裁判集刑|集民|裁判集民|訟月|東高刑時報|東高民時報|取消集|税資)"
#	pattern_top = '((昭和|平成|同)[0-9０-９]{1,3}年(\(|（).(\)|）)第[0-9０-９]{1,6}号.{0,2})'
#	pattern_mid = '((昭和|平成|同)[0-9０-９]{1,3}年[0-9０-９]{1,3}月[0-9０-９]{1,3}日(最高裁大|第.{1,2}|大)法廷判決.{0,1})'
#	pattern_sml1 = '((第|)([0-9０-９]{1,4}巻|)(第|)[0-9０-９]{1,4}号[0-9０-９]{0,5}頁)'
	pattern1 = '((昭和|平成|同)[0-9０-９]{1,3}年(\(|（).(\)|）)第[0-9０-９]{1,6}号)'
#	pattern2 = pattern_top+pattern_mid+hanreiSyuName+pattern_sml1
	extract_cite_array1 = []
	citeArray1 = []
#	extract_cite_array2 = []
#	citeArray2 = []
#	extract_cite_array3 = []
#	citeArray3 = []
	preNengo = ''
	#パターン1
	extract_cite_array1 = riyu.delete("\s　").scan(/(#{pattern1})/)
	for cite in extract_cite_array1 do
		citeArray1.push(cite[0].delete("年月日第号"))			#それぞれのcite[0]に引用判例番号が入ってる
	end
	preNengo,citeArray1 = shapeCitation(preNengo,citeArray1)		#年号が「同」となっているものを修正
#	extract_cite_array2 = riyu.delete("\s　").scan(/(#{pattern2})/)
#	for cite in extract_cite_array2 do
#		citeArray2.push(cite[0])			#それぞれのcite[0]に引用判例番号が入ってる
#	end
#	preNengo,citeArray2 = shapeCitation(preNengo,citeArray2)		#年号が「同」となっているものを修

	if citeArray1 == nil or citeArray1 == "" then
		citeArray1 = []
	end
#	if citeArray2 == nil or citeArray2 == "" then
#		citeArray2 = []
#	end

	#citeArray1にciteArray2を結合(citeArray1もしくはciteArray2がnilだとconcatでエラー出力される)
#	citeArray1.concat(citeArray2)
#	citeArray1.concat(citeArray3)
	citeArray1.uniq!
	return citeArray1
end

Dir.chdir(FILE_ROOT)
#registファイルオープン
Dir.glob(PATTERN) do |file|
	sort_hanketubun = Sort_Hanketubun.new()
	citeArray = []
	hnriSyuArray = []
	id = file.split("/")[-1].delete(".xml")
	root_dir = file.split("/")[0]
	file = open(file,"r")
	file.each{|t|
		p t
		riyu = t.chomp		#改行を消去して、riyuへ理由を格納
		#理由に含まれる、全ての漢数字をアラビア数字へ変換
		riyu = riyu.zen_to_i
		citeArray = extractCitation(riyu)
#		hanreiSyuArray = extracthanreiSyu(riyu)
	}
#追加書き込み
	File.open(OUT_PATH,'a') do |file|
		if citeArray != []
			for cite in citeArray do
				file.puts(id+","+cite)
			end
		end
	end
end




