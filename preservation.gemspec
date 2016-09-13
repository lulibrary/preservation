# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'preservation/version'

Gem::Specification.new do |spec|
  spec.name          = "preservation"
  spec.version       = Preservation::VERSION
  spec.authors       = ["Adrian Albin-Clark"]
  spec.email         = ["a.albin-clark@lancaster.ac.uk"]
  spec.summary       = %q{Ingest management for Archivematica's Automation Tools.}
  spec.description   = %q{Transfer preparation, reporting and disk space management for Archivematica's Automation Tools.}
  spec.homepage      = "https://rubygems.org/gems/preservation"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '~> 2.1'

  spec.add_runtime_dependency 'free_disk_space', '~> 1.0'
  spec.add_runtime_dependency 'puree', '~> 0.17'
  spec.add_runtime_dependency'sqlite3', '~> 1.3'
end
