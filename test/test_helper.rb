require 'test-unit'
require 'pp'

require 'record_cache'

CACHE = Memcache.new(:servers => ['localhost'])
RecordCache.config(:cache => CACHE)

ActiveRecord::Base.establish_connection(
  :adapter  => "postgresql",
  :host     => ENV.fetch('DB_HOST', 'localhost'),
  :username => `postgres',
  :password => "",
  :database => "record_cache_test"
)
ActiveRecord::Migration.verbose = false
ActiveRecord::Base.connection.client_min_messages = 'error'
