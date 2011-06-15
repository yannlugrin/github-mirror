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

describe 'Github Mirror App' do

  before(:each) do
    @app.stub!(:config).and_return({
      'mirrors' => {
        'default' => {
          'root' => File.expand_path('../../fixtures/mirrors_root', __FILE__)
        }
      }
    })
    @app.stub!(:system).and_return(true)
    @app.stub!(:`).and_return('')
  end

  it 'should read config file' do
    @app.unstub!(:config)
    @app.send(:config).should == YAML.load_file(File.expand_path('../../../config/config.yaml', __FILE__))
  end

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