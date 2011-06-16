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
  config.include Rack::Test::Methods

  config.filter_run_including :focus  => true
  config.run_all_when_everything_filtered = true

  config.mock_with :rspec

  config.before(:each) do
    @app = GithubMirrorApp.new
  end
end

# Add an app method for RSpec
def app
  @app
end

