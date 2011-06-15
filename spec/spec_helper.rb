# encoding: utf-8
ENV['RACK_ENV'] ||= 'test'

# Requires testing libraries
require 'rack/test'
require 'rspec'

# Require application
require File.expand_path('../../lib/github_mirror_app', __FILE__)

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path('../support/**/*.rb', __FILE__)].each {|f| require f}

# Configure Rspec
RSpec.configure do |config|
  config.mock_with :rspec

  # Include the Rack test methods
  config.include Rack::Test::Methods
end

# Add an app method for RSpec
def app
  GithubMirrorApp.new
end

