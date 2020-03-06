# 削除対象のPMID一覧をファイルに出力

require 'zlib'
require 'rexml/document'
require 'nokogiri'

input = ARGV[0]
output = ARGV[1]
pmid_list = []

# 削除対象のPMIDを取得
Zlib::GzipReader.open(input){|gz|
  docx = Nokogiri::XML(gz.read)
  docx.xpath('/PubmedArticleSet/DeleteCitation/PMID').each{|elm|
    pmid_list.push(elm.text)    
  } 
}

# ファイルにPMID一覧を出力
File.open(output, 'a'){|file|
  pmid_list.each{|pmid|
    file.puts pmid
  }
}

