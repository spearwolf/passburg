# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "passburg/version"

Gem::Specification.new do |s|
  s.name        = "passburg"
  s.version     = Passburg::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Wolfger Schramm"]
  s.email       = ["wolfger@spearwolf.de"]
  s.homepage    = "https://github.com/spearwolf/passburg"
  s.summary     = %q{command line tool to store and find passwords in a secure way}
  s.description = %q{command line tool to store and find passwords in a secure way}

  s.rubyforge_project = "passburg"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "highline", ">=1.6.1"
end
