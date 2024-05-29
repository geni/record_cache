require 'rubygems'
gem 'mocha'
require 'minitest/autorun'
require 'mocha/minitest'
require 'shoulda'
require 'pp'

require 'record_cache'

CACHE = Memcache.new(:servers => ['localhost'])
ActiveRecord::Base.establish_connection(
  :adapter  => "postgresql",
  :host     => "localhost",
  :username => `whoami`.chomp.tr('.', '_'),
  :password => "",
  :database => "record_cache_test"
)
ActiveRecord::Migration.verbose = false
ActiveRecord::Base.connection.client_min_messages = 'panic'
