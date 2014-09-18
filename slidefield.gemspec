# coding: utf-8
lib = File.expand_path '../lib', __FILE__
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib
require 'slidefield/version'

Gem::Specification.new do |spec|
  spec.name          = "slidefield"
  spec.version       = SlideField::VERSION
  spec.authors       = ["cfi30"]
  spec.email         = ["slidefield@cfillion.tk"]
  spec.summary       = %q{A presentation software that reads plain text files written in its own interpreted language.}
  spec.homepage      = "https://bitbucket.org/cfi30/slidefield"
  spec.license       = "GPL-3.0+"

  spec.files         = `git ls-files -z`.split "\x0"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename f }
  spec.test_files    = spec.files.grep %r{^(test|spec|features)/}
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'minitest', '~> 5.4'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'simplecov', '~> 0.9'

  spec.add_runtime_dependency 'awesome_print', '~> 1.2'
  spec.add_runtime_dependency 'gosu', '~> 0.8'
  spec.add_runtime_dependency 'parslet', '~> 1.6'
end
