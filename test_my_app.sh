#!/bin/sh

bundle _1.17.3_ config --local clean true
bundle _1.17.3_ config --local path vendor/bundle
bundle _1.17.3_ config --local without vscode
bundle _1.17.3_ install

# Clean and recreate test database
DB_HOST=${DB_HOST:-localhost}
dropdb -h ${DB_HOST} -U postgres --if-exists record_cache_test
createdb -h ${DB_HOST} -U postgres record_cache_test

bundle _1.17.3_ exec rake test

