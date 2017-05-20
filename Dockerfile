FROM ruby:2.3.3-alpine

# Dependencias
RUN apk update && \
    apk add git build-base libxml2 libxslt

WORKDIR /srv/indexador-input-rss

ENV BUNDLE_JOBS 4
COPY Gemfile* ./
RUN bundle install --deployment --without development test
COPY . /srv/indexador-input-rss/

EXPOSE 3000

CMD ["bundle", "exec", "rackup", "-p", "9292", "-o", "0.0.0.0"]
