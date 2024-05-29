source "http://www.rubygems.org"

gemspec

gem "memcache", :git => 'https://github.com/stangel/memcache.git'

group :development do
  git 'https://github.com/makandra/rails.git', :branch => '2-3-lts' do
    gem 'rails', '~>2.3.18'
    gem 'actionmailer',     :require => false
    gem 'actionpack',       :require => false
    gem 'activerecord',     :require => false
    gem 'activeresource',   :require => false
    gem 'activesupport',    :require => false
    gem 'railties',         :require => false
    gem 'railslts-version', :require => false
  end

  gem 'activerecord-postgresql-adapter'
  gem 'json'
  gem 'minitest'
  gem 'mocha'
  gem 'rake'
  gem 'shoulda', '~>3'
  gem 'test-unit'
end