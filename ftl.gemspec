# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ftl/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Matt Petty"]
  gem.email         = ["matt@kizmeta.com"]
  gem.description   = %q{Ftl is a command line tool for Fog/AWS}
  gem.summary       = %q{Ftl is a command line tool for Fog/AWS}
  gem.homepage      = "http://github.com/lodestone/ftl"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "ftl"
  gem.require_paths = ["lib"]
  gem.version       = Ftl::VERSION
  gem.add_development_dependency('rdoc')
  gem.add_development_dependency('aruba')
  gem.add_development_dependency('rake','~> 0.9.2')
  gem.add_dependency('fog')
  gem.add_dependency('formatador', '~> 0.2.2')
end
