# coding: utf-8
lib = File.expand_path '../lib', __FILE__
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib
require 'slidefield/version'

Gem::Specification.new do |spec|
  spec.name          = "slidefield"
  spec.version       = SlideField::VERSION
  spec.authors       = ["cfi30"]
  spec.email         = ["git@cfillion.tk"]
  spec.summary       = %q{TODO: Write a short summary. Required.}
  spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split "\x0"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename f }
  spec.test_files    = spec.files.grep %r{^(test|spec|features)/}
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'minitest', '~> 5.3'
  spec.add_development_dependency 'rake'

  spec.add_runtime_dependency 'awesome_print', '~> 1.2'
  spec.add_runtime_dependency 'gosu', '~> 0.7'
  spec.add_runtime_dependency 'parslet', '~> 1.6'
end
