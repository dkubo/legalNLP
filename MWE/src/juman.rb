#coding:utf-8

class JumanParser
  def initialize(name)
    @name = name
    @juman_s = nil
    @knp_s = nil
  end
  
  def juman_socket(name, port, option)
    until @juman_s
      begin 
        @juman_s = TCPSocket.open(name,port)
      rescue
        STDERR.print "JUMANとの接続に失敗しました。再接続しています。\n"
        sleep 5
        retry
      end
    end
    STDERR.print "JUMANに接続しました\n"
    @juman_s.write("RUN -e2\n")
    return
  end

	def juman_parse(input)
		juman_result_a = Array.new
    @juman_s.write(input+"\n")
		while true
			f = @juman_s.gets
			juman_result_a.push(f)
			break if f.to_s == "EOS\n"
		end
		return juman_result_a
	end

	def juman_close
		@juman_s.close
	end

end
