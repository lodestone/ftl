# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "httparty"
  s.version = "0.8.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Nunemaker", "Sandro Turriate"]
  s.date = "2012-04-22"
  s.description = "Makes http fun! Also, makes consuming restful web services dead easy."
  s.email = ["nunemaker@gmail.com"]
  s.executables = ["httparty"]
  s.files = ["bin/httparty"]
  s.homepage = "http://httparty.rubyforge.org/"
  s.post_install_message = "When you HTTParty, you must party hard!"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.11"
  s.summary = "Makes http fun! Also, makes consuming restful web services dead easy."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<multi_json>, ["~> 1.0"])
      s.add_runtime_dependency(%q<multi_xml>, [">= 0"])
    else
      s.add_dependency(%q<multi_json>, ["~> 1.0"])
      s.add_dependency(%q<multi_xml>, [">= 0"])
    end
  else
    s.add_dependency(%q<multi_json>, ["~> 1.0"])
    s.add_dependency(%q<multi_xml>, [">= 0"])
  end
end
