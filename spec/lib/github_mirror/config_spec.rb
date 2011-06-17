# encoding: utf-8
require 'github_mirror/config'
require 'spec_helper'

describe GithubMirror::Config do
  subject { GithubMirror::Config }

  let(:config_file) { File.expand_path('../../../../config/config.yml', __FILE__) }

  it '::config should return GithubMirror::Config instance' do
    GithubMirror::Config.config.should be_a(GithubMirror::Config)
  end

  context '::load' do

    it 'should require an argument' do
      lambda { subject.load }.should raise_error(ArgumentError, /wrong number of arguments \(0 for 1\)/)
    end

    it 'should return self' do
      subject.load({}).should == subject.instance
    end

    describe 'from file' do

      it 'should raise an error if file not exist' do
        lambda { subject.load("fake_#{rand(99999)}.yml") }.should raise_error(ArgumentError, /file must exist/)
      end

      it 'should raise an error if file have syntax error' do
        Tempfile.open('fake.yaml') do |config_file|
          config_file.write("- test:\ntest: true")
          config_file.flush
          lambda { subject.load(config_file.path) }.should raise_error(ArgumentError, /syntax error/)
        end
      end

      it 'should raise an error if can\'t be parsed to Hash' do
        Tempfile.open('fake.yaml') do |config_file|
          lambda { subject.load(config_file.path) }.should raise_error(ArgumentError, /file content must be a Hash/)
        end
      end

    end

    it 'should raise an error if argument is not a valid file or a Hash' do
      lambda { subject.load([]) }.should raise_error(ArgumentError, /must be a valid file path or Hash/)
    end

  end

  context '::token' do

    it 'should respond' do
      lambda { subject.token }.should_not raise_error(NoMethodError)
    end

    it 'should return nil by default' do
      subject.token.should be_nil
    end

    describe 'on load' do

      it 'should be nil by default' do
        subject.load({})
        subject.token.should be_nil
      end

      it 'should be set with string' do
        subject.load({
          'token' => 'TOKEN'
        })
        subject.token.should == 'TOKEN'
      end

      it 'should be set with integer' do
        subject.load({
          'token' => 12345
        })
        subject.token.should == '12345'
      end

      it 'should be striped' do
        subject.load({
          'token' => '  TOKEN  '
        })
        subject.token.should == 'TOKEN'
      end

      it 'should be frozen' do
        subject.load({
          'token' => '  TOKEN  '
        })
        subject.token.should be_frozen
      end

      it 'should be nil on striped empty string' do
        subject.load({
          'token' => '  '
        })
        subject.token.should be_nil
      end

    end

  end
end
