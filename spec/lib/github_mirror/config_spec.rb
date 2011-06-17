# encoding: utf-8
require 'github_mirror/config'
require 'spec_helper'

describe GithubMirror::Config do
  subject { GithubMirror::Config.instance }

  let(:config_file) { File.expand_path('../../../../config/config.yml', __FILE__) }

  it '::config should return GithubMirror::Config instance' do
    GithubMirror::Config.config.should be_a(GithubMirror::Config)
  end

  context '#load' do

    it 'should require an argument' do
      lambda { subject.send(:load) }.should raise_error(ArgumentError, /wrong number of arguments \(0 for 1\)/)
    end

    describe 'from file' do

      it 'should raise an error if file not exist' do
        lambda { subject.send(:load, "fake_#{rand(99999)}.yml") }.should raise_error(ArgumentError, /File must exist/)
      end

      it 'should raise an error if file have syntax error' do
        Tempfile.open('fake.yaml') do |config_file|
          config_file.write("- test:\ntest: true")
          config_file.flush
          lambda { subject.send(:load, config_file.path) }.should raise_error(ArgumentError, /syntax error/)
        end
      end

      it 'should raise an error if can\'t be parsed to Hash' do
        Tempfile.open('fake.yaml') do |config_file|
          lambda { subject.send(:load, config_file.path) }.should raise_error(ArgumentError, /File content must be a Hash/)
        end
      end

    end

  end
end
