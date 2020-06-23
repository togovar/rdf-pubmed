FROM ruby

ADD ./ /
ADD ./init_pubmed /bin
ADD ./convert_pubmed /bin

RUN mkdir /data && mkdir /work
RUN gem install nokogiri
RUN chmod 777 /bin/init_pubmed /bin/convert_pubmed

CMD convert_pubmed 

