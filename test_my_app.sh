#!/bin/sh

bundle config --local clean true
bundle config --local path vendor/bundle
bundle config --local without vscode

# The bundler version can change between branches
rm -f Gemfile.lock

bundle install

bundle exec rake test

