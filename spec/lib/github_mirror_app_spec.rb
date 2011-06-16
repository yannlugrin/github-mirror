require 'spec_helper'

GITHUB_JSON = JSON.parse(
<<-GITHUB_JSON
{
  "before": "5aef35982fb2d34e9d9d4502f6ede1072793222d",
  "repository": {
    "url": "http://github.com/defunkt/github",
    "name": "github",
    "owner": {
      "email": "chris@ozmm.org",
      "name": "defunkt"
    }
  },
  "commits": {
    "41a212ee83ca127e3c8cf465891ab7216a705f59": {
      "url": "http://github.com/defunkt/github/commit/41a212ee83ca127e3c8cf465891ab7216a705f59",
      "author": {
        "email": "chris@ozmm.org",
        "name": "Chris Wanstrath"
      },
      "message": "okay i give in",
      "timestamp": "2008-02-15T14:57:17-08:00"
    },
    "de8251ff97ee194a289832576287d6f8ad74e3d0": {
      "url": "http://github.com/defunkt/github/commit/de8251ff97ee194a289832576287d6f8ad74e3d0",
      "author": {
        "email": "chris@ozmm.org",
        "name": "Chris Wanstrath"
      },
      "message": "update pricing a tad",
      "timestamp": "2008-02-15T14:36:34-08:00"
    }
  },
  "after": "de8251ff97ee194a289832576287d6f8ad74e3d0",
  "ref": "refs/heads/master"
}
GITHUB_JSON
)

INVALID_JSON = JSON.parse(
<<-INVALID_JSON
{
}
INVALID_JSON
)

describe 'GithubMirrorApp' do

  before(:each) do
    YAML.stub!(:load_file).and_return(config)
    @app.stub!(:system).and_return(true)
    @app.stub!(:`).and_return('')
  end

  context '#config' do

    it 'should parse YAML config file' do
      YAML.should_receive(:load_file).with(File.expand_path('../../../config/config.yml', __FILE__)).and_return({})
      @app.send(:config, 'repository_owner', 'repository_name')
    end

    it 'should be a Struct' do
      @app.send(:config, 'repository_owner', 'repository_name').should be_a Struct
    end

    it 'should have allowed key set to false by default' do
      YAML.stub!(:load_file).and_return({})
      @app.send(:config, 'repository_owner', 'repository_name', true).allowed.should == false
    end

    it 'should have path key set to nil by default' do
      YAML.stub!(:load_file).and_return({})
      @app.send(:config, 'repository_owner', 'repository_name', true).path.should == nil
    end

    it 'should have patterns key set to empty hash by default' do
      YAML.stub!(:load_file).and_return({})
      @app.send(:config, 'repository_owner', 'repository_name', true).patterns.should == {}
    end

    it 'should set key with "*/*" matcher' do
      YAML.stub!(:load_file).and_return({'*/*' => {'allowed' => true}})
      @app.send(:config, 'repository_owner', 'repository_name', true).allowed.should == true

      YAML.stub!(:load_file).and_return({'*/*' => {'allowed' => false}})
      @app.send(:config, 'repository_owner', 'repository_name', true).allowed.should == false
    end

    it 'should set key with "repository_owner*/*" matcher' do
      YAML.stub!(:load_file).and_return({'*/*' => {'allowed' => false}, 'repository_owner*/*' => {'allowed' => true}})
      @app.send(:config, 'repository_owner', 'repository_name', true).allowed.should == true

      YAML.stub!(:load_file).and_return({'*/*' => {'allowed' => true}, 'repository_owner*/*' => {'allowed' => false}})
      @app.send(:config, 'repository_owner', 'repository_name', true).allowed.should == false
    end

    it 'should set key with "repository_owner/*" matcher' do
      YAML.stub!(:load_file).and_return({'repository_owner*/*' => {'allowed' => false}, 'repository_owner/*' => {'allowed' => true}})
      @app.send(:config, 'repository_owner', 'repository_name', true).allowed.should == true

      YAML.stub!(:load_file).and_return({'repository_owner*/*' => {'allowed' => true}, 'repository_owner/*' => {'allowed' => false}})
      @app.send(:config, 'repository_owner', 'repository_name', true).allowed.should == false
    end

    it 'should set key with "repository_owner/repository_name*" matcher' do
      YAML.stub!(:load_file).and_return({'repository_owner/*' => {'allowed' => false}, 'repository_owner/repository_name*' => {'allowed' => true}})
      @app.send(:config, 'repository_owner', 'repository_name', true).allowed.should == true

      YAML.stub!(:load_file).and_return({'repository_owner/*' => {'allowed' => true}, 'repository_owner/repository_name*' => {'allowed' => false}})
      @app.send(:config, 'repository_owner', 'repository_name', true).allowed.should == false
    end

    it 'should set key with "repository_owner/repository_name" matcher' do
      YAML.stub!(:load_file).and_return({'repository_owner/repository_name*' => {'allowed' => false}, 'repository_owner/repository_name' => {'allowed' => true}})
      @app.send(:config, 'repository_owner', 'repository_name', true).allowed.should == true

      YAML.stub!(:load_file).and_return({'repository_owner/repository_name*' => {'allowed' => true}, 'repository_owner/repository_name' => {'allowed' => false}})
      @app.send(:config, 'repository_owner', 'repository_name', true).allowed.should == false
    end

    it 'should not set value if be nil' do
      YAML.stub!(:load_file).and_return({'*/*' => {'allowed' => true}, 'repository_owner/repository_name' => {'allowed' => nil}})
      @app.send(:config, 'repository_owner', 'repository_name', true).allowed.should == true
    end

  end

  context '#mirror_path' do

    it 'should append repository_name to path wihtout replacement key' do
     YAML.stub!(:load_file).and_return(config({
        '*/*' => {
          'allowed' => true,
          'path'    => '/tmp/repo/'
        }
      }))
      @app.send(:mirror_path, 'owner_name', 'repo_name').should == '/tmp/repo/repo_name.git'
    end

    it 'should replace :repository_name key with repository name value if don\'t have pattern for repository_name' do
      YAML.stub!(:load_file).and_return(config({
        '*/*' => {
          'allowed'  => true,
          'path'     => '/tmp/repo/:repository_name.git',
          'patterns' => nil
        }
      }))
      @app.send(:mirror_path, 'owner_name', 'repo_name').should == '/tmp/repo/repo_name.git'
    end

    it 'should replace :repository_name key with value matched by pattern for repository_name key' do
      YAML.stub!(:load_file).and_return(config({
        '*/*' => {
          'allowed'  => true,
          'path'     => '/tmp/repo/:repository_name.git',
          'patterns' => {
            'repository_name' => '^[^\-]+\-(.+)'
          }
        }
      }))
      @app.send(:mirror_path, 'owner_name', 'before-repo_name').should == '/tmp/repo/repo_name.git'
    end

    it 'should replace :custom_name key with value matched by pattern for custom_name key' do
      YAML.stub!(:load_file).and_return(config({
        '*/*' => {
          'allowed'  => true,
          'path'     => '/tmp/repo/:custom_name.git',
          'patterns' => {
            'custom_name' => '^[^\-]+\-(.+)'
          }
        }
      }))
      @app.send(:mirror_path, 'owner_name', 'before-repo_name').should == '/tmp/repo/repo_name.git'
    end

    it 'should replace multiples keys with value matched by key patterns' do
      YAML.stub!(:load_file).and_return(config({
        '*/*' => {
          'allowed'  => true,
          'path'     => '/tmp/repo/:custom_dir/:custom_name.git',
          'patterns' => {
            'custom_dir' => '^([^\-]+)',
            'custom_name' => '^[^\-]+\-(.+)'
          }
        }
      }))
      @app.send(:mirror_path, 'owner_name', 'before-repo_name').should == '/tmp/repo/before/repo_name.git'
    end

    it 'should replace :repository_owner key with repository owner value if don\'t have pattern for repository_owner' do
      YAML.stub!(:load_file).and_return(config({
        '*/*' => {
          'allowed'  => true,
          'path'     => '/tmp/repo/:repository_owner/:repository_name.git',
          'patterns' => nil
        }
      }))
      @app.send(:mirror_path, 'owner_name', 'repo_name').should == '/tmp/repo/owner_name/repo_name.git'
    end

    it 'should replace :repository_owner key with value matched by pattern for repository_owner key' do
      YAML.stub!(:load_file).and_return(config({
        '*/*' => {
          'allowed'  => true,
          'path'     => '/tmp/repo/:repository_owner/:repository_name.git',
          'patterns' => {
            'repository_owner' => '^([^\-]+)'
          }
        }
      }))
      @app.send(:mirror_path, 'owner_name', 'custom_owner-repo_name').should == '/tmp/repo/custom_owner/custom_owner-repo_name.git'
    end

  end

  context '#handle_request' do

    it 'should reply with fail message on GET' do
      get '/'

      last_response.should be_ok
      last_response.body.should =~ /fail:/
    end

    it 'should reply with fail message on POST without payload' do
      post '/'

      last_response.should be_ok
      last_response.body.should =~ /fail:/
    end

    it 'should reply with fail message on POST with empty payload' do
      post '/', :payload => ''

      last_response.should be_ok
      last_response.body.should =~ /fail:/
    end

    it 'should reply with fail message on POST with invalid payload' do
      post '/', :payload => INVALID_JSON.to_json

      last_response.should be_ok
      last_response.body.should =~ /fail:/
    end

    it 'should reply with success message on POST with valid payload' do
      post '/', :payload => GITHUB_JSON.to_json

      last_response.should be_ok
      last_response.body.should == 'done'
    end

    it 'should reply with fail message if owner is not allowed to be mirrored' do
      YAML.stub!(:load_file).and_return(config({"#{repository_owner}/*" => {'allowed' => false}}))

      post '/', :payload => GITHUB_JSON.to_json

      last_response.should be_ok
      last_response.body.should =~ /fail:/
    end

    it 'should reply with succes message if all owner\'s repositories is allowed to be mirrored' do
      YAML.stub!(:load_file).and_return(config({"#{repository_owner}/*" => {'allowed' => true}}))

      post '/', :payload => GITHUB_JSON.to_json

      last_response.should be_ok
      last_response.body.should == 'done'
    end

    it 'should reply with fail message if repository is not allowed to be mirrored' do
      YAML.stub!(:load_file).and_return(config({"#{repository_owner}/#{repository_name}" => {'allowed' => false}}))

      post '/', :payload => GITHUB_JSON.to_json

      last_response.should be_ok
      last_response.body.should =~ /fail:/
    end

    it 'should reply with success message if repository is allowed to be mirrored' do
      YAML.stub!(:load_file).and_return(config({"#{repository_owner}/#{repository_name}" => {'allowed' => true}}))

      post '/', :payload => GITHUB_JSON.to_json

      last_response.should be_ok
      last_response.body.should == 'done'
    end

    it 'should use git url for repository if is public' do
      repository_private(false)
      File.should_receive(:exist?).with(mirror_path).and_return(false)
      @app.should_receive(:system).with(/git:\/\/github\.com\/#{repository_owner}\/#{repository_name}/).and_return(true)

      post '/', :payload => GITHUB_JSON.to_json
    end

    it 'should use ssh url for repository if is private' do
      repository_private(true)
      File.should_receive(:exist?).with(mirror_path).and_return(false)
      @app.should_receive(:system).with(/git@github\.com:#{repository_owner}\/#{repository_name}/).and_return(true)

      post '/', :payload => GITHUB_JSON.to_json
    end

    it 'should clone repository if mirror doesn\'t exist' do
      File.should_receive(:exist?).with(mirror_path).and_return(false)
      @app.should_receive(:system).with("git clone --mirror --origin github_mirroring #{repository_url} #{mirror_path}").and_return(true)

      post '/', :payload => GITHUB_JSON.to_json
    end

    it 'should add github url to remote if mirror exist but doesn\'t have githuib remote' do
      File.should_receive(:exist?).with(mirror_path).and_return(true)
      @app.should_receive(:`).with("cd #{mirror_path}; git remote").and_return('')
      @app.should_receive(:system).with("cd #{mirror_path}; git remote add --mirror github_mirroring #{repository_url}").and_return(true)
      @app.should_receive(:system).with("cd #{mirror_path}; git fetch github_mirroring").and_return(true)

      post '/', :payload => GITHUB_JSON.to_json
    end

    it 'should not add github url to remote if mirror exist and is configured' do
      File.should_receive(:exist?).with(mirror_path).and_return(true)
      @app.should_receive(:`).with("cd #{mirror_path}; git remote").and_return('github_mirroring')
      @app.should_not_receive(:system).with(/git remote add/)
      @app.should_receive(:system).with("cd #{mirror_path}; git fetch github_mirroring").and_return(true)

      post '/', :payload => GITHUB_JSON.to_json
    end

  end
end