FROM ruby

ADD ./ /
ADD ./convert_pubmed /bin

RUN mkdir /data && mkdir /work
ADD ./dup_pmid.tsv /work

RUN gem install nokogiri
RUN chmod 777 /bin/convert_pubmed

ENTRYPOINT ["convert_pubmed"]

