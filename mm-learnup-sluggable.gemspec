# -*- encoding: utf-8 -*-
# stub: mm-learnup-sluggable 0.3.4 ruby lib

Gem::Specification.new do |s|
  s.name = "mm-learnup-sluggable"
  s.version = "0.3.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Scott Taylor"]
  s.date = "2015-06-25"
  s.email = "scott@railsnewbie.com"
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["LICENSE", "README.rdoc", "Rakefile", "lib/mm-learnup-sluggable.rb", "spec"]
  s.homepage = "http://github.com/GoLearnup/mm-learnup-sluggable"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.rubygems_version = "2.4.5"
  s.summary = "MongoMapper plugin to cache a slugged version of a field.  Originally forked from mm-learnup-sluggable."

  if s.respond_to? :specification_version then
    s.specification_version = 4

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
