# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'woody/version'

Gem::Specification.new do |gem|
  gem.name          = "woody"
  gem.version       = Woody::VERSION
  gem.authors       = ["David Robertson"]
  gem.email         = ["david@davidr.me"]
  gem.description   = "Woody"
  gem.summary       = "Podcast Static Site Generator"
  gem.homepage      = "https://github.com/DavidJRobertson/woody"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_runtime_dependency 'erubis'
  gem.add_runtime_dependency 'mp3info'
  gem.add_runtime_dependency 'aws-s3'
  gem.add_runtime_dependency 'commander'
  
  # gem.post_install_message = "This update modifies default templates. Please run `woody update_templates` in your site directory to update them. Warning: this will destroy any modifications to your templates."
end
