FROM ruby

ADD ./ /

RUN mkdir /data && mkdir /work

CMD bash pubmed.sh
 

