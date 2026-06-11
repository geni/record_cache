require 'rubygems'
gem 'mocha'
gem 'test-unit'
require 'test/unit'
require 'mocha/test_unit'
require 'shoulda'
require 'pp'

require 'record_cache'

CACHE = Memcache.new(:servers => ['localhost'])
ActiveRecord::Base.establish_connection(
  :adapter  => "postgresql",
  :host     => ENV.fetch('DB_HOST', 'localhost'),
  :username => 'postgres',
  :password => "",
  :database => "record_cache_test"
)
ActiveRecord::Migration.verbose = false
# 'panic' is no longer valid in modern PostgreSQL, use 'error' instead
ActiveRecord::Base.connection.client_min_messages = 'warning'
# Set logger for Rails 3.0 (needed for scope() method)
require 'logger'
ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = Logger::ERROR
