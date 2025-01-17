#coding:utf-8
#Westlawから判決文取得

require 'watir'
require 'watir-webdriver'

class Search_Westlaw
	def initialize()
		@WESTLAW_LOGIN_PAGE = "http://go.westlawjapan.com/wljp/app/signon"
		@WESTLAW_TOP_PAGE = "https://go.westlawjapan.com/wljp/app/welcome"
		@WESTLAW_JISYO_TOP = "http://vpass.cloudapp.net/Default.aspx?dic=VPYougo"
		@browser = Watir::Browser.new:firefox
	end
######login######
	def login()
#		@browser.goto(@WESTLAW_JISYO_TOP)
		@browser.goto(@WESTLAW_TOP_PAGE)
#		@browser.text_field(:name => "UserIDTextBox").set "2101421"					#idセット
#		@browser.text_field(:name => "PasswordTextBox").set "wakuwakumojar"		#pasセット
#		@browser.button(:name => "PasswordLoginButton").click									#login
		@browser.text_field(:name => "uid").set "2101421"					#idセット
		@browser.text_field(:name => "pwd").set "wakuwakumojar"		#pasセット
#		@browser.button(:name => "PasswordLoginButton").click									#login
		@browser.button(:name => "Logon").click									#login
	end

######logout######
	def logout()
		@browser.image(:alt => "ログアウト").click
	end
#####検索セッティング#####
	def search_setting()
	#トップへ移動
		@browser.goto(@WESTLAW_TOP_PAGE)
	#有斐閣DBへ移動
		puts @browser.a(:href => "#").attribute_value('onclick')
#		@browser.a(:text => tmp).when_present.click
		#@browser.goto(tmp)
		#@browser.html
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



search = Search_Westlaw.new()
search.login()
search.search_setting()
#search.wait(15)
search.logout()
#search.close()



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




