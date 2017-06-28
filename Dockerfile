FROM ruby:latest

WORKDIR /frederick_api_gem
ADD Gemfile /frederick_api_gem
ADD frederick_api.gemspec /frederick_api_gem
ADD lib/frederick_api/version.rb /frederick_api_gem/lib/frederick_api/version.rb

RUN bundle install -j8

ENV DOCKER=true
