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
  # VSCode ruby-lsp plugin uses these.
  # Normally they're installed by the plugin using .ruby-lsp/Gemfile
  # If we don't put them here, they'll be removed if we run bundle install
  gem 'prism', '~> 1.9.0',    :require => false
  gem 'rbs',                  :require => false
  gem 'ruby-lsp', '>=0.18.0', :require => false
  gem 'ruby-lsp-rails',       :require => false
end
