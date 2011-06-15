source "http://rubygems.org"

gem 'rack'
gem 'json'

group :development, :test do
  gem 'rspec'
  gem 'rack-test'

  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-bundler'
end

group :linux do
  gem 'rb-inotify', ['>= 0.8.5',  '~> 0.8']
  gem 'libnotify'
end

group :osx do
  gem 'rb-fsevent'
  gem 'growl'
end

