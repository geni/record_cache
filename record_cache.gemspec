lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "record_cache"
  gem.version       = IO.read('VERSION')
  gem.authors       = ["Justin Balthrop"]
  gem.email         = ["git@justinbalthrop.com"]
  gem.description   = %q{Active Record caching and indexing in memcache.}
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/ninjudd/record_cache"
  gem.license       = 'MIT'

  gem.add_dependency 'deferrable',    '>= 0.1.0'
  gem.add_dependency 'activerecord',  '~> 8.0.0'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
