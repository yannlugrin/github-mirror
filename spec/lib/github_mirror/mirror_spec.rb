# encoding: utf-8
require 'github_mirror/mirror'
require 'spec_helper'

describe GithubMirror::Mirror do
  subject { GithubMirror::Mirror.new(repository_owner, repository_name) }

  let(:repository_owner) { 'repository_owner' }
  let(:repository_name)  { 'repository_name'  }

  it 'should have owner attribute' do
    subject.should respond_to(:owner)
  end

  it 'should have name attribute' do
    subject.should respond_to(:name)
  end

  describe 'initialization' do

    it 'should set repository owner' do
      GithubMirror::Mirror.new('custom_owner', repository_name).owner.should == 'custom_owner'
    end

    it 'shoud raise error if repository owner is nil' do
      lambda do
        GithubMirror::Mirror.new(nil, repository_name)
      end.should raise_error(ArgumentError, /owner attribute can't be empty/)
    end

    it 'shoud raise error if repository owner is not a string' do
      lambda do
        GithubMirror::Mirror.new(12345, repository_name)
      end.should raise_error(ArgumentError, /owner attribute can't be empty/)
    end

    it 'shoud raise error if repository owner is empty' do
      lambda do
        GithubMirror::Mirror.new('', repository_name)
      end.should raise_error(ArgumentError, /owner attribute can't be empty/)
    end

    it 'should set repository name' do
      GithubMirror::Mirror.new(repository_owner, 'custom_name').name.should == 'custom_name'
    end

    it 'shoud raise error if repository name is nil' do
      lambda do
        GithubMirror::Mirror.new(repository_owner, nil)
      end.should raise_error(ArgumentError, /name attribute can't be empty/)
    end

    it 'shoud raise error if repository name is not a string' do
      lambda do
        GithubMirror::Mirror.new(repository_owner, 12345)
      end.should raise_error(ArgumentError, /name attribute can't be empty/)
    end

    it 'shoud raise error if repository name is empty' do
      lambda do
        GithubMirror::Mirror.new(repository_owner, '')
      end.should raise_error(ArgumentError, /name attribute can't be empty/)
    end

  end

  context '#path' do

    it 'should append owner_name/repository_name.git to path wihtout replacement key' do
      stub_repository_info(:path  => '/tmp/repo/')
      subject.path.should == "/tmp/repo/#{repository_owner}/#{repository_name}.git"
    end

    it 'should replace :repository_name key with repository name value if don\'t have pattern for repository_name' do
      stub_repository_info(:path  => '/tmp/repo/:repository_name.git')
      subject.path.should == "/tmp/repo/#{repository_name}.git"
    end

    it 'should replace :repository_name key with value matched by pattern for repository_name' do
      stub!(:repository_name).and_return('before-repository_name')
      stub_repository_info(
        :path     => '/tmp/repo/:repository_name.git',
        :patterns => {
          'repository_name' => '^[^\-]+\-(.+)'
        }
      )
      subject.path.should == '/tmp/repo/repository_name.git'
    end

    it 'should replace :repository_owner key with repository owner value if don\'t have pattern for repository_owner' do
      stub_repository_info(:path  => '/tmp/repo/:repository_owner/:repository_name.git')
      subject.path.should == "/tmp/repo/#{repository_owner}/#{repository_name}.git"
    end

    it 'should replace :repository_owner key with value matched by pattern for repository_owner' do
      stub!(:repository_name).and_return('before-repo_name')
      stub_repository_info(
        :path     => '/tmp/repo/:repository_owner/:repository_name.git',
        :patterns => {
          'repository_owner' => '^([^\-]+)'
        }
      )
      subject.path.should == '/tmp/repo/before/before-repo_name.git'
    end

    it 'should replace :custom_name key with value matched by pattern for custom_name' do
      stub!(:repository_name).and_return('before-repository_name')
      stub_repository_info(
        :path     => '/tmp/repo/:custom_name.git',
        :patterns => {
          'custom_name' => '^[^\-]+\-(.+)'
        }
      )
      subject.path.should == '/tmp/repo/repository_name.git'
    end

    it 'should replace multiples keys with value matched by key patterns' do
      stub!(:repository_name).and_return('before-repository_name')
      stub_repository_info(
        :path     => '/tmp/repo/:custom_dir/:custom_name.git',
        :patterns => {
          'custom_dir'  => '^([^\-]+)',
          'custom_name' => '^[^\-]+\-(.+)'
        }
      )
      subject.path.should == '/tmp/repo/before/repository_name.git'
    end

  end
end
