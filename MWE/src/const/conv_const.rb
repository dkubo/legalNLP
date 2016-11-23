#coding:utf-8

require 'json'

def mergeConst(c_hash)
	file_a = open("const1.tsv",'r')
	file_a.each_line{|l|
		c_list = []
		sig, const_list = l.chomp.split("\t")
		const_list.split(";").each{|const|
			c_list.push(const.split(","))
		}
		c_hash[sig] = c_list
	}

	file_b = open("const2.tsv",'r')
	file_b.each_line{|l|
		new_list = []
		sig, const_list = l.chomp.split("\t")
		const_list.split(";").each{|const|
			if new_list == []
				new_list = c_hash[const]
			else
				new_list += c_hash[const]
			end
		}
		c_hash[sig] = new_list
	}

	puts JSON.pretty_generate(c_hash)
end

def writeFile(str)
	File.open("const1_unidic.tsv", "a") do |f|
		f.puts(str)
	end
end

def convUnidic()
	file = open("IPA_UNIDIC.tsv", 'r')
	file.each_line{|l|
		constid = l.split("\t")[0]
		const =  l.split("\t")[3].delete("\"\s\n\r")
		# puts constid +"\t"+ const
		writeFile(constid +"\t"+ const)
		# c_hash[constid] = const.delete("\"\s\n\r").split(";")
	}
end

def main()
	c_hash = {}
	convUnidic()
	# writeJSON("./const.json", sig_list)

end

main()
