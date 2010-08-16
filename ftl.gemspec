# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ftl}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Petty"]
  s.date = %q{2010-08-16}
  s.default_executable = %q{ftl}
  s.description = %q{FTL spins up and down Amazon EC2 instances for pair programming}
  s.email = %q{matt@kizmeta.com}
  s.executables = ["ftl"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc",
     "TODO"
  ]
  s.files = [
    ".document",
     ".gems",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "TODO",
     "VERSION",
     "bin/ftl",
     "config.ru",
     "ftl.gemspec",
     "lib/ftl.rb",
     "lib/ftl/client.rb",
     "lib/ftl/server.rb",
     "test/helper.rb",
     "test/test_ftl.rb"
  ]
  s.homepage = %q{http://github.com/lodestone/ftl}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Easily launch ec2 instances for pair programming}
  s.test_files = [
    "test/helper.rb",
     "test/test_ftl.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    else
      s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
  end
end

