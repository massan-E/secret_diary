FROM ruby:3.4.5

WORKDIR /app
ENV BUNDLE_PATH=/usr/local/bundle
COPY Gemfile Gemfile.lock ./
RUN bundle install
