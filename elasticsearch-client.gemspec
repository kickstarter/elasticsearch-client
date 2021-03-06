# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "elasticsearch/version"

Gem::Specification.new do |s|
  s.name        = "elasticsearch-client"
  s.version     = ElasticSearch::VERSION
  s.authors     = ["Jonathan Hoyt"]
  s.email       = ["hoyt@github.com"]
  s.homepage    = ""
  s.summary     = %q{ElasticSearch ruby client.}
  s.description = %q{ElasticSearch ruby client.}

  s.rubyforge_project = "elasticsearch-client"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]


  s.add_dependency 'faraday', '~> 0.9'
  s.add_dependency 'faraday_middleware', '~> 0.9'
  s.add_dependency 'excon'
  s.add_dependency 'yajl-ruby', '~> 1.2.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
end
