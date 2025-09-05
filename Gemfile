source "http://www.rubygems.org"

gemspec

gem 'cache_version', git: 'https://github.com/geni/cache_version.git', branch: 'rails-8'
gem 'memcache', git: 'https://github.com/stangel/memcache.git', branch: 'ruby-3'

group :development do
  gem 'activerecord', '~>8.0'
  gem 'method_source' # for bin/test
  gem 'pg', '~>1.5.0' # 1.6 requires GLIBC 2.29 which CentOS 8 Stream doesn't have
  gem 'rake'
  gem 'test-unit'
end

group :vscode do
  gem 'debase',           :require => false
  gem 'debug',            :require => false
  gem 'rainbow',          :require => false
  gem 'rdbg',             :require => false
  gem 'ruby-debug-ide',   :require => false
  gem 'ruby-lsp',         :require => false
  gem 'solargraph',       :require => false
end
