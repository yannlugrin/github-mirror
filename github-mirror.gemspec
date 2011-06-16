# -*- encoding: utf-8 -*-
Kernel.load File.expand_path('../lib/github_mirror/version.rb', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'github-mirror'
  s.version     = GithubMirror::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Yann Lurgin']
  s.email       = ['yann.lugrin@sans-savoir.net']
  s.homepage    = 'https://github.com/yannlugrin/github-mirror'
  s.summary     = 'Github Mirror is a Rack application to mirroring your Github repositories'
  s.description = 'Github Mirror is a Rack application to handle hooks request from Github and mirroring your repositories'

  s.required_rubygems_version = '>= 1.3.6'
  s.rubyforge_project = 'github-mirror'

  s.add_dependency 'rack', '~> 1.3'
  s.add_dependency 'json', '~> 1.5'

  s.add_development_dependency 'bundler',       '~> 1.0'
  s.add_development_dependency 'rspec',         '~> 2.6'
  s.add_development_dependency 'rack-test',     '~> 0.6'
  s.add_development_dependency 'guard',         '~> 0.4'
  s.add_development_dependency 'guard-rspec',   '~> 0.4'
  s.add_development_dependency 'guard-bundler', '~> 0.1'

  s.files        = Dir.glob('lib/**/*') + %w[LICENSE README.md]
  s.require_path = 'lib'
end
