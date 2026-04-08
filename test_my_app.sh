#!/bin/sh

bundle config --local clean true
bundle config --local path vendor/bundle
bundle config --local without vscode
bundle install

bundle exec rake test

