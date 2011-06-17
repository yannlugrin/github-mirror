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

end
