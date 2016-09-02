FROM ruby:alpine
ADD ./dreamdns.rb /usr/src/dreamdns.rb
WORKDIR /usr/src
CMD ["ruby", "./dreamdns.rb"]
