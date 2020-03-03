
require 'zlib'
require 'rexml/document'
require 'erb'
require 'date'

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
end

# 要素の存在チェック
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

# ファイルごとに出力を行う
Zlib::GzipReader.open(input){|gz|
  docx = REXML::Document.new(gz.read)
  docx.elements.each('/PubmedArticleSet/PubmedArticle') do |doc|
    
    pmid = doc.elements[pmid_path].text
    
    # 削除対象エントリーの場合は作成しない
    next if delete_pmids.include?(pmid)

    ab = check_element(doc.elements[ab_path]) ? doc.elements[ab_path].text : ""
    ci = check_element(doc.elements[ci_path]) ? doc.elements[ci_path].text : ""
    aid_pii = check_element(doc.elements[aid_pii_path]) ? doc.elements[aid_pii_path].text : ""
    aid_doi = check_element(doc.elements[aid_doi_path]) ? doc.elements[aid_doi_path].text : ""
    
    au_index = 0
    au_info = Struct.new(:index, :init, :lname, :fname, :ad, :auid)
    au_list = Array.new()
    doc.elements.each(au_path) do |elm|
      
      next if elm.elements["CollectiveName"]
     
      au_list[au_index] = au_info.new()
      au_list[au_index].index = au_index + 1
      au_list[au_index].init = check_element(elm.elements["Initials"]) ? elm.elements["Initials"].text : ""
      au_list[au_index].fname = check_element(elm.elements["ForeName"]) ? elm.elements["ForeName"].text : ""
       au_list[au_index].lname = check_element(elm.elements["LastName"]) ? elm.elements["LastName"].text : ""
      au_list[au_index].ad = check_element(elm.elements["AffiliationInfo/Affiliation"]) ? elm.elements["AffiliationInfo/Affiliation"].text : ""
      au_list[au_index].auid = check_element(elm.elements["AffiliationInfo/Identifer"]) ? elm.elements["AffiliationInfo/Identifer"].text : ""
      au_index +=1
    end
    
    cn = check_element(doc.elements[cn_path]) ? doc.elements[cn_path].text : ""
    crdt = check_element(doc.elements[crdt_year_path]) ? doc.elements[crdt_year_path].text : ""
    crdt <<= check_element(doc.elements[crdt_month_path]) ? "-#{doc.elements[crdt_month_path].text}" : ""
    crdt <<= check_element(doc.elements[crdt_day_path]) ? "-#{doc.elements[crdt_day_path].text}" : ""
    crdt <<= check_element(doc.elements[crdt_hour_path]) ? "T#{zero_padding(doc.elements[crdt_hour_path].text)}" : ""
    crdt <<= check_element(doc.elements[crdt_minute_path]) ? ":#{zero_padding(doc.elements[crdt_minute_path].text)}" : ""
    lr = check_element(doc.elements[lr_year_path]) ? doc.elements[lr_year_path].text : ""
    lr <<= check_element(doc.elements[lr_month_path]) ? "-#{doc.elements[lr_month_path].text}" : ""
    lr <<= check_element(doc.elements[lr_day_path]) ? "-#{doc.elements[lr_day_path].text}" : ""
    edat = check_element(doc.elements[edat_year_path]) ? doc.elements[edat_year_path].text : ""
    edat <<= check_element(doc.elements[edat_month_path]) ? "-#{doc.elements[edat_month_path].text}" : ""
    edat <<= check_element(doc.elements[edat_day_path]) ? "-#{doc.elements[edat_day_path].text}" : ""
    edat <<= check_element(doc.elements[edat_hour_path]) ? "T#{zero_padding(doc.elements[edat_hour_path].text)}" : ""
    edat <<= check_element(doc.elements[edat_minute_path]) ? ":#{zero_padding(doc.elements[edat_minute_path].text)}" : ""
    
    ir_index = 0
    ir_info = Struct.new(:index, :init, :lname, :fname, :irad)
    ir_list = Array.new()
    doc.elements.each(ir_path) do |elm|
      ir_list[ir_index] = ir_info.new()
      ir_list[ir_index].index = ir_index + 1
      ir_list[ir_index].init = check_element(elm.elements["Initials"]) ? elm.elements["Initials"].text : ""
      ir_list[ir_index].fname = check_element(elm.elements["ForeName"]) ? elm.elements["ForeName"].text : ""
      ir_list[ir_index].lname = check_element(elm.elements["LastName"]) ? elm.elements["LastName"].text : ""
      ir_list[ir_index].irad = check_element(elm.elements["AffiliationInfo/Affiliation"]) ? elm.elements["AffiliationInfo/Affiliation"].text : ""
      ir_index +=1
    end
    
    is_p = check_element(doc.elements[is_p_path]) ? doc.elements[is_p_path].text : ""
    is_e = check_element(doc.elements[is_e_path]) ? doc.elements[is_e_path].text : ""
    is_l = check_element(doc.elements[is_l_path]) ? doc.elements[is_l_path].text : ""
    ip = check_element(doc.elements[ip_path]) ? doc.elements[ip_path].text : ""
    ta = check_element(doc.elements[ta_path]) ? doc.elements[ta_path].text : ""
    jt = check_element(doc.elements[jt_path]) ? doc.elements[jt_path].text : ""
    la = check_element(doc.elements[la_path]) ? doc.elements[la_path].text : ""
    
    jid = check_element(doc.elements[jid_path]) ? doc.elements[jid_path].text : "" 
    oci = check_element(doc.elements[oci_path]) ? doc.elements[oci_path].text : ""
    own = check_element(doc.elements[own_path]) ? doc.elements[own_path].attributes['Owner'] : ""
    
    pg, pg_st, pg_en, pg_so = "", "", "", "" 
    if check_element(doc.elements[pg_path])then
      if doc.elements[pg_path].text.include?(" ") then
        pg = doc.elements[pg_path].text
        pg_so = doc.elements[pg_path].text
      elsif doc.elements[pg_path].text.include?("-")
        pg_st = doc.elements[pg_path].text.split("-")[0]
        pg_en = doc.elements[pg_path].text.split("-")[1]
        pg_so = doc.elements[pg_path].text
      else
        pg = doc.elements[pg_path].text
        pg_so = doc.elements[pg_path].text
      end      
    end
    
    pl = check_element(doc.elements[pl_path]) ? doc.elements[pl_path].text : ""
       
    rn, nm = [], []
    doc.elements.each(rn_list_path) do |elm|
      rn.push(elm.elements['RegistryNumber'].text) if check_element(elm.elements['RegistryNumber'])
      nm.push(elm.elements['NameOfSubstance'].text) if check_element(elm.elements['NameOfSubstance'])
    end
    
    ti = check_element(doc.elements[ti_path]) ? doc.elements[ti_path].text : ""
    vi = check_element(doc.elements[vi_path]) ? doc.elements[vi_path].text : ""
    dp = check_element(doc.elements[dp_year_path]) ? doc.elements[dp_year_path].text : ""
    dp <<= check_element(doc.elements[dp_month_path]) ? "-#{zero_padding(doc.elements[dp_month_path].text)}" : ""
    dp <<= check_element(doc.elements[dp_day_path]) ? "-#{zero_padding(doc.elements[dp_day_path].text)}" : ""
    so = "#{ta}. #{dp};#{vi}(#{ip}):#{pg_so}."
   
    # 出力
    erb = ERB.new(IO.read("/pubmed_converter.erb"),nil, "%" )
    File.open(output, 'a'){|f|
      f.puts erb.result(binding).gsub(/\n(\s| )*\n/, "\n")
    }
  end
}

