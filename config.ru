#!/usr/bin/env rackup

begin
  require 'rubygems'
  require 'github-mirror'
rescue LoadError
  require File.dirname(__FILE__) + '/lib/github_mirror'
end

use Rack::CommonLogger
use Rack::Lint
run GithubMirror.new