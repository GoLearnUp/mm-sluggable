# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "mm-learnup-sluggable"
  s.version = "0.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Scott Taylor"]
  s.date = "2014-07-10"
  s.email = "scott@railsnewbie.com"
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["LICENSE", "Rakefile", "README.rdoc", "spec", "lib/mm-learnup-sluggable.rb"]
  s.homepage = "http://github.com/GoLearnup/mm-learnup-sluggable"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "MongoMapper plugin to cache a slugged version of a field.  Originally forked from mm-learnup-sluggable."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mongo_mapper>, [">= 0.9.0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<mongo_mapper>, [">= 0.9.0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<mongo_mapper>, [">= 0.9.0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end