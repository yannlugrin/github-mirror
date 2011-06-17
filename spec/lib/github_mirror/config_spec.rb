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

      it 'should be set on reload' do
        subject.load({})
        subject.token.should be_nil

        subject.load({
          'token' => 'TOKEN'
        })
        subject.token.should == 'TOKEN'
      end

    end

  end

  context '::repository_info' do

    describe 'on load' do

      it 'should be an empty Hash by default' do
        subject.load({})
        subject.instance.instance_variable_get(:@repositories_config).should == {}
      end

      it 'should be set with configuration Hash' do
        config = {
          'repositories' => {
            '*/*' => {
              'allowed' => true
            }
          }
        }

        subject.load(config)
        subject.instance.instance_variable_get(:@repositories_config).should == config['repositories']
      end

      it 'should be set on reload' do
        config = {
          'repositories' => {
            '*/*' => {
              'allowed' => true
            }
          }
        }

        subject.load({})
        subject.instance.instance_variable_get(:@repositories_config).should == {}

        subject.load(config)
        subject.instance.instance_variable_get(:@repositories_config).should == config['repositories']
      end

    end

    it 'should require tow arguments' do
      lambda { subject.repository_info }.should raise_error(ArgumentError, /wrong number of arguments \(0 for 2\)/)
    end

    it 'should be a "RepositoryInfo" Struct' do
      subject.repository_info('repository_owner', 'repository_name').should be_a Struct
      subject.repository_info('repository_owner', 'repository_name').should be_a GithubMirror::Config::RepositoryInfo
    end

    it 'allowed should be false by default' do
      subject.repository_info('repository_owner', 'repository_name').allowed.should == false
    end

    it 'path should be `[working dir]/repositories` by default' do
      subject.repository_info('repository_owner', 'repository_name').path.should == File.expand_path('./repositories')
    end

    it 'patterns should be empty by default' do
      subject.repository_info('repository_owner', 'repository_name').patterns.should == {}
    end

    it 'should set values from "*/*" matcher' do
      subject.load({'repositories' => {'*/*' => {'allowed' => true}}})
      subject.repository_info('repository_owner', 'repository_name').allowed.should == true

      subject.load({'repositories' => {'*/*' => {'allowed' => false}}})
      subject.repository_info('repository_owner', 'repository_name').allowed.should == false
    end

    it 'should set values from "repository_owner*/*" matcher' do
      subject.load({'repositories' => {'*/*' => {'allowed' => false}, 'repository_owner*/*' => {'allowed' => true}}})
      subject.repository_info('repository_owner', 'repository_name').allowed.should == true

      subject.load({'repositories' => {'*/*' => {'allowed' => true}, 'repository_owner*/*' => {'allowed' => false}}})
      subject.repository_info('repository_owner', 'repository_name').allowed.should == false
    end

    it 'should set values from "repository_owner/*" matcher' do
      subject.load({'repositories' => {'repository_owner*/*' => {'allowed' => false}, 'repository_owner/*' => {'allowed' => true}}})
      subject.repository_info('repository_owner', 'repository_name').allowed.should == true

      subject.load({'repositories' => {'repository_owner*/*' => {'allowed' => true}, 'repository_owner/*' => {'allowed' => false}}})
      subject.repository_info('repository_owner', 'repository_name').allowed.should == false
    end

    it 'should set values from "repository_owner/repository_name*" matcher' do
      subject.load({'repositories' => {'repository_owner/*' => {'allowed' => false}, 'repository_owner/repository_name*' => {'allowed' => true}}})
      subject.repository_info('repository_owner', 'repository_name').allowed.should == true

      subject.load({'repositories' => {'repository_owner/*' => {'allowed' => true}, 'repository_owner/repository_name*' => {'allowed' => false}}})
      subject.repository_info('repository_owner', 'repository_name').allowed.should == false
    end

    it 'should set values from "repository_owner/repository_name" matcher' do
      subject.load({'repositories' => {'repository_owner/repository_name*' => {'allowed' => false}, 'repository_owner/repository_name' => {'allowed' => true}}})
      subject.repository_info('repository_owner', 'repository_name').allowed.should == true

      subject.load({'repositories' => {'repository_owner/repository_name*' => {'allowed' => true}, 'repository_owner/repository_name' => {'allowed' => false}}})
      subject.repository_info('repository_owner', 'repository_name').allowed.should == false
    end

    it 'should not set value if be nil' do
      subject.load({'repositories' => {'*/*' => {'allowed' => true}, 'repository_owner/repository_name' => {'allowed' => nil}}})
      subject.repository_info('repository_owner', 'repository_name').allowed.should == true
    end

  end
end
