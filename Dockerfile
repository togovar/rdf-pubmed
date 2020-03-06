FROM ruby

ADD ./ /

RUN mkdir /data && mkdir /work
RUN gem install nokogiri


CMD bash pubmed.sh
 

