
require 'zlib'
require 'erb'
require 'benchmark'
require 'objspace'
require 'nokogiri'

# プロパティ値
ab_path = "MedlineCitation/Article/Abstract/AbstractText"
ci_path = "MedlineCitation/Article/Abstract/CopyrightInformation" 
aid_pii_path = "PubmedData/ArticleIdList/ArticleId[@IdType='pii']"
aid_doi_path = "PubmedData/ArticleIdList/ArticleId[@IdType='doi']"
au_path =  "MedlineCitation/Article/AuthorList/Author"
cn_path = "MedlineCitation/Article/AuthorList/Author/CollectiveName"
crdt_path = "PubmedData/History/PubMedPubDate[@PubStatus='pubmed']"
crdt_year_path = "#{crdt_path}/Year"
crdt_month_path = "#{crdt_path}/Month"
crdt_day_path = "#{crdt_path}/Day"
crdt_hour_path = "#{crdt_path}/Hour"
crdt_minute_path = "#{crdt_path}/Minute"
lr_path = "MedlineCitation/DateRevised"
lr_year_path = "#{lr_path}/Year"
lr_month_path = "#{lr_path}/Month"
lr_day_path = "#{lr_path}/Day"
edat_path = "PubmedData/History/PubMedPubDate[@PubStatus='entrez']"
edat_year_path = "#{edat_path}/Year"
edat_month_path = "#{edat_path}/Month"
edat_day_path = "#{edat_path}/Day"
edat_hour_path = "#{edat_path}/Hour"
edat_minute_path = "#{edat_path}/Minute"
ir_path = "MedlineCitation/InvestigatorList/Investigator" 
is_p_path = "MedlineCitation/Article/Journal/ISSN[@IssnType='Print']"
is_e_path = "MedlineCitation/Article/Journal/ISSN[@IssnType='Electronic']"
is_l_path = "MedlineCitation/MedlineJournalInfo/ISSNLinking"
ip_path = "MedlineCitation/Article/Journal/JournalIssue/Issue"
ta_path = "MedlineCitation/MedlineJournalInfo/MedlineTA"
jt_path = "MedlineCitation/Article/Journal/Title"
la_path = "MedlineCitation/Article/Language"
mh_list_path ="MedlineCitation/MeshHeadingList/MeshHeading"
jid_path = "MedlineCitation/MedlineJournalInfo/NlmUniqueID"
oci_path = "MedlineCitation/OtherAbstract"
own_path = "MedlineCitation"
pg_path = "MedlineCitation/Article/Pagination/MedlinePgn"
pl_path = "MedlineCitation/MedlineJournalInfo/Country"
pmid_path = "MedlineCitation/PMID"
rn_list_path = "MedlineCitation/ChemicalList/Chemical"
ti_path = "MedlineCitation/Article/ArticleTitle"
vi_path = "MedlineCitation/Article/Journal/JournalIssue/Volume"
dp_path = "MedlineCitation/Article/Journal/JournalIssue/PubDate"
dp_year_path = "#{dp_path}/Year"
dp_month_path = "#{dp_path}/Month"
dp_day_path = "#{dp_path}/Day"

prefix = [ 
  ": <http://purl.jp/bio/10/pubmed-ontology/> .",
  "orcid: <https://orcid.org/> .",
  "nlmcatalog: <https://www.ncbi.nlm.nih.gov/nlmcatalog/> .",
  "fabio: <http://purl.org/spar/fabio/> .",
  "dcterms: <http://purl.org/dc/terms/> .",
  "org: <http://www.w3.org/ns/org#> .",
  "rdfs: <http://www.w3.org/2000/01/rdf-schema#> .",
  "foaf: <http://xmlns.com/foaf/0.1/> .",
  "bibo: <http://purl.org/ontology/bibo/> .",
  "pubmed: <http://rdf.ncbi.nlm.gov/pubmed/> .",
  "prism: <http://prismstandard.org/namespeces/1.2/basic/> .",
  "olo: <http://purl.org/ontology/olo/core#> .",
  "pav: <http://purl.org/pav/>."
]

# 2桁の0埋め
def zero_padding num
  num.to_s.length==2 ? num : ("0"<<num) 
end #{

def check_element(element)
  if (element && element.text) then
    true
  else
    false
  end
end

input = ARGV[0]
delete_pmids_file = ARGV[1] 
output = "/data/#{File.basename(input, '.xml.gz')}.ttl"

# 削除対象PMIDのリストを取得
delete_pmids = []
File.foreach(delete_pmids_file){ |line|
  delete_pmids.push(line.chomp)
}

# prefixの記述
File.open(output, 'a'){|f|
  prefix.each{ |p| f.puts("@prefix "+ p )}
}
erb = ERB.new(IO.read("/pubmed_converter.erb"),nil, "%" )
# ファイルごとに出力を行う

ir_info = Struct.new(:index, :init, :lname, :fname, :irad)

gz = Zlib::GzipReader.new(File.open(input))
#docx = REXML::Document.new(gz.read)
  
docx = Nokogiri::XML(gz.read)

docx.xpath('/PubmedArticleSet/PubmedArticle').each do |doc|
    
  pmid = doc.xpath(pmid_path).text
    
  # 削除対象エントリーの場合は作成しない
  next if delete_pmids.include?(pmid)

  ab = check_element(doc.xpath(ab_path)) ? doc.xpath(ab_path).text : ""
  ci = check_element(doc.xpath(ci_path)) ? doc.xpath(ci_path).text : ""
  aid_pii = check_element(doc.xpath(aid_pii_path)) ? doc.xpath(aid_pii_path).text : ""
  aid_doi = check_element(doc.xpath(aid_doi_path)) ? doc.xpath(aid_doi_path).text : ""
    
  au_index = 0
  au_list = []
  au_info = Struct.new(:index, :init, :lname, :fname, :ad, :auid)  
  doc.xpath(au_path).each do |elm|
    
    next if !elm.xpath("CollectiveName").empty?
    
     
    au_list[au_index] = au_info.new()
    au_list[au_index].index = au_index + 1
    au_list[au_index].init = check_element(elm.xpath("Initials")) ? elm.xpath("Initials").text : ""
    au_list[au_index].fname = check_element(elm.xpath("ForeName")) ? elm.xpath("ForeName").text : ""
    au_list[au_index].lname = check_element(elm.xpath("LastName")) ? elm.xpath("LastName").text : ""
    au_list[au_index].ad = check_element(elm.xpath("AffiliationInfo/Affiliation")) ? elm.xpath("AffiliationInfo/Affiliation").text : ""
    au_list[au_index].auid = check_element(elm.xpath("AffiliationInfo/Identifer")) ? elm.xpath("AffiliationInfo/Identifer").text : ""
    au_index +=1
  end
    
  cn = check_element(doc.xpath(cn_path)) ? doc.xpath(cn_path).text : ""
  crdt = check_element(doc.xpath(crdt_year_path)) ? doc.xpath(crdt_year_path).text : ""
  crdt <<= check_element(doc.xpath(crdt_month_path)) ? "-#{doc.xpath(crdt_month_path).text}" : ""
  crdt <<= check_element(doc.xpath(crdt_day_path)) ? "-#{doc.xpath(crdt_day_path).text}" : ""
  crdt <<= check_element(doc.xpath(crdt_hour_path)) ? "T#{zero_padding(doc.xpath(crdt_hour_path).text)}" : ""
  crdt <<= check_element(doc.xpath(crdt_minute_path)) ? ":#{zero_padding(doc.xpath(crdt_minute_path).text)}" : ""
  lr = check_element(doc.xpath(lr_year_path)) ? doc.xpath(lr_year_path).text : ""
  lr <<= check_element(doc.xpath(lr_month_path)) ? "-#{doc.xpath(lr_month_path).text}" : ""
  lr <<= check_element(doc.xpath(lr_day_path)) ? "-#{doc.xpath(lr_day_path).text}" : ""
  edat = check_element(doc.xpath(edat_year_path)) ? doc.xpath(edat_year_path).text : ""
  edat <<= check_element(doc.xpath(edat_month_path)) ? "-#{doc.xpath(edat_month_path).text}" : ""
  edat <<= check_element(doc.xpath(edat_day_path)) ? "-#{doc.xpath(edat_day_path).text}" : ""
  edat <<= check_element(doc.xpath(edat_hour_path)) ? "T#{zero_padding(doc.xpath(edat_hour_path).text)}" : ""
  edat <<= check_element(doc.xpath(edat_minute_path)) ? ":#{zero_padding(doc.xpath(edat_minute_path).text)}" : ""
    
  ir_index = 0
  ir_list = []
  doc.xpath(ir_path).each do |elm|
    ir_list[ir_index] = ir_info.new()
    ir_list[ir_index].index = ir_index + 1
    ir_list[ir_index].init = check_element(elm.xpath("Initials")) ? elm.xpath("Initials").text : ""
    ir_list[ir_index].fname = check_element(elm.xpath("ForeName")) ? elm.xpath("ForeName").text : ""
    ir_list[ir_index].lname = check_element(elm.xpath("LastName")) ? elm.xpath("LastName").text : ""
    ir_list[ir_index].irad = check_element(elm.xpath("AffiliationInfo/Affiliation")) ? elm.xpath("AffiliationInfo/Affiliation").text : ""
    ir_index +=1
  end
    
  is_p = check_element(doc.xpath(is_p_path)) ? doc.xpath(is_p_path).text : ""
  is_e = check_element(doc.xpath(is_e_path)) ? doc.xpath(is_e_path).text : ""
  is_l = check_element(doc.xpath(is_l_path)) ? doc.xpath(is_l_path).text : ""
  ip = check_element(doc.xpath(ip_path)) ? doc.xpath(ip_path).text : ""
  ta = check_element(doc.xpath(ta_path)) ? doc.xpath(ta_path).text : ""
  jt = check_element(doc.xpath(jt_path)) ? doc.xpath(jt_path).text : ""
  la = check_element(doc.xpath(la_path)) ? doc.xpath(la_path).text : ""
    
  jid = check_element(doc.xpath(jid_path)) ? doc.xpath(jid_path).text : "" 
  oci = check_element(doc.xpath(oci_path)) ? doc.xpath(oci_path).text : ""
  own = check_element(doc.xpath(own_path)) ? doc.xpath(own_path).attribute('Owner').text : ""
    
  pg, pg_st, pg_en, pg_so = "", "", "", "" 
  if check_element(doc.xpath(pg_path))then
    if doc.xpath(pg_path).text.include?(" ") then
      pg = doc.xpath(pg_path).text
      pg_so = doc.xpath(pg_path).text
    elsif doc.xpath(pg_path).text.include?("-")
      pg_st = doc.xpath(pg_path).text.split("-")[0]
      pg_en = doc.xpath(pg_path).text.split("-")[1]
      pg_so = doc.xpath(pg_path).text
    else
      pg = doc.xpath(pg_path).text
      pg_so = doc.xpath(pg_path).text
    end      
  end
    
  pl = check_element(doc.xpath(pl_path)) ? doc.xpath(pl_path).text : ""
     
  rn, nm = [], []
  doc.xpath(rn_list_path).each do |elm|
    rn.push(elm.xpath('RegistryNumber').text) if check_element(elm.xpath('RegistryNumber'))
    nm.push(elm.xpath('NameOfSubstance').text) if check_element(elm.xpath('NameOfSubstance'))
  end
   
  ti = check_element(doc.xpath(ti_path)) ? doc.xpath(ti_path).text : ""
  vi = check_element(doc.xpath(vi_path)) ? doc.xpath(vi_path).text : ""
  dp = check_element(doc.xpath(dp_year_path)) ? doc.xpath(dp_year_path).text : ""
  dp <<= check_element(doc.xpath(dp_month_path)) ? "-#{zero_padding(doc.xpath(dp_month_path).text)}" : ""
  dp <<= check_element(doc.xpath(dp_day_path)) ? "-#{zero_padding(doc.xpath(dp_day_path).text)}" : ""
  so = "#{ta}. #{dp};#{vi}(#{ip}):#{pg_so}."
  
  # 出力
  File.open(output, 'a') do |f|
    f.puts erb.result(binding).gsub(/\n(\s| )*\n/, "\n")
  end
end


 



