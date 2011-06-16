source 'http://rubygems.org'

gemspec

# run `bundle install --without=linux` first time to ignore linux
# dependencies
group :linux do
  gem 'rb-inotify', ['>= 0.8.5',  '~> 0.8']
  gem 'libnotify'
end

# run `bundle install --without=osx` first time to ignore osx
# dependencies
group :osx do
  gem 'rb-fsevent'
  gem 'growl'
end

