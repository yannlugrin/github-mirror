# encoding: utf-8

begin
  require 'rubygems'
  require 'github_mirror'
rescue LoadError
  require File.expand_path('../../lib/github_mirror', __FILE__)
end

use Rack::CommonLogger
use Rack::Lint
run GithubMirror.new
