require 'spec_helper'

GITHUB_JSON = <<-GITHUB_JSON
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

describe 'Github Mirror App' do

  it 'should read config file' do
    app.send(:config).should == YAML.load_file(File.expand_path('../../../config/config.yaml', __FILE__))
  end

  it 'should reply with fail message on GET' do
    get '/'

    last_response.should be_ok
    last_response.body.should == 'fail'
  end

  it 'should reply with fail message on POST without payload' do
    post '/'

    last_response.should be_ok
    last_response.body.should == 'fail'
  end

  it 'should reply with fail message on POST with empty payload' do
    post '/', :payload => ''

    last_response.should be_ok
    last_response.body.should == 'fail'
  end

  it 'should reply with succes message on POST with valid payload' do
    post '/', :payload => GITHUB_JSON

    last_response.should be_ok
    last_response.body.should == 'done'
  end
end