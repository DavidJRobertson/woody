# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'podgen/version'

Gem::Specification.new do |gem|
  gem.name          = "podgen"
  gem.version       = Podgen::VERSION
  gem.authors       = ["David Robertson"]
  gem.email         = ["david@davidr.me"]
  gem.description   = "PodGen"
  gem.summary       = "Podcast Static Site Generator"
  gem.homepage      = "http://davidr.me"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_runtime_dependency 'erubis'
  gem.add_runtime_dependency 'mp3info'
  gem.add_runtime_dependency 'aws-s3'
  gem.add_runtime_dependency 'commander'  
end
