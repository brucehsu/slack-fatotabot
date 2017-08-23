FROM ruby:2.4.1
RUN set -ex && \
    apt-get update && \
    apt-get install libpq-dev -y && \
    gem install rake
