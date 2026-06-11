source "http://www.rubygems.org"

gemspec

gem "memcache", :git => 'https://github.com/stangel/memcache.git'

group :development do
  gem 'rails', '3.0.20'
  gem 'activerecord-postgresql-adapter'
  gem 'json'
  gem 'minitest', '~> 4.7'
  gem 'mocha'
  gem 'pg', '~> 1.2.3'
  gem 'rake'
  gem 'shoulda', '~>3'
  gem 'test-unit'
end

group :vscode do
  # VSCode debugging gems for Rails 3.0
  gem 'ruby-debug-ide',    :require => false
  gem 'ruby-debug-base19', :require => false
end
