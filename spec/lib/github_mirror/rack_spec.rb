# encoding: utf-8
require 'github_mirror/rack'
require 'spec_helper'

describe GithubMirror::Rack do
  subject { GithubMirror::Rack.new }

  context '#call' do

    it 'should require an argument' do
      lambda { subject.call }.should raise_error(ArgumentError, /wrong number of arguments \(0 for 1\)/)
    end

  end

end
