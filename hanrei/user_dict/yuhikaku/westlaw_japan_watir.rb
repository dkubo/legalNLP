#coding:utf-8
#Westlawから判決文取得

require 'watir'
require 'watir-webdriver'

class Search_Westlaw
	def initialize()
		@WESTLAW_LOGIN_PAGE = "http://go.westlawjapan.com/wljp/app/signon"
		@WESTLAW_TOP_PAGE = "https://go.westlawjapan.com/wljp/app/welcome"
		@browser = Watir::Browser.new:firefox
	end
######login######
	def login()
		@browser.goto(@WESTLAW_LOGIN_PAGE)
		@browser.text_field(:name => "uid").set "2101421"					#idセット
		@browser.text_field(:name => "pwd").set "wakuwakumojar"		#pasセット
		@browser.button(:name => "Logon").click									#login
	end

######logout######
	def logout()
		@browser.image(:alt => "ログアウト").click
	end
	def search_setting()
	#トップへ移動
		@browser.goto(@WESTLAW_TOP_PAGE)
	#判例タブへ移動
		@browser.li(:id => "casesTab").click
	end
######事件番号で検索######
	def search_input(nengo,year,kigo,num)
	#年号入力
		p nengo
		@browser.select_list(:name , "ddlCaseNumEra").select(nengo)
	#年入力
		@browser.text_field(:id , "ddlCaseNumYear_flexselect").value = year
	#事件記録符号入力
		@browser.text_field(:id , "fldCourtId").value = kigo
	#事件番号入力
		@browser.text_field(:id , "fldCaseNum").value = num
	#検索
		@browser.button(:name => "btnSubmit").click
	end
######ダウンロード######
	def download()
		@browser.image(:alt => "download").click
	#pdf選択
		#browser.radio(:value => "selectBox").set
		wait(10)
		@browser.button(:id => "submitButton").click
	end
######wait######
	def wait(t)
		@browser.driver.manage.timeouts.implicit_wait = t.to_i	#wait 1sec		
	end
######ブラウザクローズ######
	def close()
		@browser.close
	end
end


#セレクトリストを期間指定にチェック
#browser.select_list(:name , "ddlJudDateRestriction").select("期間指定")

#西暦で検索できるように設定
#browser.select_list(:name , "ddlJudEra").select("西暦")
#browser.select_list(:name , "ddlJudEraBetween").select("西暦")

#検索期間指定(検索結果が1万件を超えないように指定すること)

#一年間隔で検索
#year_range = 1869..2014
#year_range.each{|year|
#	search_range(browser,year)	
#	browser.button(:name => "btnSubmit").click	#検索 
#	download(browser)
#}
#




