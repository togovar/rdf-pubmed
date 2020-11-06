##
# baselineにある重複したPMIDの更新日の新しいものを
# PMID 更新日でTSVファイルに出力する
##

require 'csv'
require 'zlib'
require 'erb'
require 'benchmark'
require 'objspace'
require 'nokogiri'

pmid_path = "MedlineCitation/PMID"
lr_path = "MedlineCitation/DateRevised"
lr_year_path = "#{lr_path}/Year"
lr_month_path = "#{lr_path}/Month"
lr_day_path = "#{lr_path}/Day"


# baselineにあるファイルの一覧を取得
baselines = Dir.glob("/work/baseline/*.xml.gz").sort
pmids_info = []
dup_info = []
result_pmids = []
result = []

# 各PMIDと更新日(DateLastRevised)を取得
for input in baselines do
  gz = Zlib::GzipReader.new(File.open(input))
  docx = Nokogiri::XML(gz.read)
  pmid_info = []
  docx.xpath('/PubmedArticleSet/PubmedArticle').each do |doc|
    pmid = doc.xpath(pmid_path).text
    lr = doc.xpath(lr_year_path).text + doc.xpath(lr_month_path).text + doc.xpath(lr_day_path).text
    pmid_info.push([pmid, lr])    
  end
  File.open("/pmid_info.tsv", 'a'){|file|
  pmid_info.each{|pmid, lr|
    file.puts pmid + "\t" + lr
  }
}
end

pmids_info = CSV.read("/pmid_info.tsv", col_sep: "\t")

# PMIDの一覧を抽出し、重複しているPMIDのみに変換する
dup_pmids = pmids_info.transpose[0].group_by{|e| e }.reject{|k,v| v.one?}.keys

# PMID,更新日の一覧から重複しているPMIDの情報だけ抽出する
pmids_info.each do |pmid, lr|
  if dup_pmids.include?(pmid)
    dup_info.push([pmid, lr])
  end
end

# 更新日の降順ソートし順に結果一覧に追加していく、結果一覧に存在するPMIDの場合はスキップする
dup_info = dup_info.sort_by{|row| row[1]}.reverse
dup_info.each do |pmid, lr|
  if !result_pmids.include?(pmid)
    result.push([pmid, lr])
    result_pmids.push(pmid)
  end
end

# ファイルに出力
File.open("/work/dup_pmid.tsv", 'a'){|file|
  result.each{|pmid, lr|
    file.puts pmid + "\t" + lr
  }
}


