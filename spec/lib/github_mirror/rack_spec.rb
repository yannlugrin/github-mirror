# encoding: utf-8
require 'github_mirror/rack'
require 'spec_helper'

describe GithubMirror::Rack do
  include ::Rack::Test::Methods

  subject { GithubMirror::Rack.new }

  let(:mock_request) { mock('request', :finish => [200, {}, []], :write => nil) }
  let(:mock_mirror ) { mock('mirror',  :update => true) }

  let(:app) { subject }

  before(:each) do
    GithubMirror::Mirror.stub!(:load_from_payload).and_return(mock_mirror)
  end

  context '#call' do

    it 'should require an argument' do
      lambda { subject.call }.should raise_error(ArgumentError, /wrong number of arguments \(0 for 1\)/)
    end

    it 'should instanciate request' do
      ::Rack::Request.should_receive(:new).with({})
      subject.call({})
    end

    it 'should instanciate response' do
      ::Rack::Response.should_receive(:new).with(no_args).and_return(mock_request)
      subject.call({})
    end

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
    GithubMirror::Mirror.stub!(:load_from_payload).and_return { raise(ArgumentError) }

    post '/', :payload => INVALID_JSON.to_json

    last_response.should be_ok
    last_response.body.should =~ /fail:/
  end

  it 'should reply with success message on POST with valid payload' do
    post '/', :payload => GITHUB_JSON.to_json

    last_response.should be_ok
    last_response.body.should == 'done'
  end

  it 'should reply with success message on POST if token match' do
    app.stub!(:config).and_return(mock('config', :token => 'TOKEN'))

    post '/TOKEN', :payload => GITHUB_JSON.to_json

    last_response.should be_ok
    last_response.body.should == 'done'
  end

  it 'should reply with fail message on POST if token not match' do
    app.stub!(:config).and_return(mock('config', :token => 'TOKEN'))

    post '/FAILTOKEN', :payload => GITHUB_JSON.to_json

    last_response.should be_ok
    last_response.body.should =~ /fail:/
  end

  it 'should reply with success message on POST if no token is configured' do
    app.stub!(:config).and_return(mock('config', :token => nil))

    post '/TOKEN', :payload => GITHUB_JSON.to_json

    last_response.should be_ok
    last_response.body.should == 'done'
  end

  pending 'should reply with fail message if owner is not allowed to be mirrored' do
    @app.stub!(:config).and_return(config({'repositories' => {"#{repository_owner}/*" => {'allowed' => false}}}))

    post '/', :payload => GITHUB_JSON.to_json

    last_response.should be_ok
    last_response.body.should =~ /fail:/
  end

  pending 'should reply with succes message if all owner\'s repositories is allowed to be mirrored' do
    @app.stub!(:config).and_return(config({'repositories' => {"#{repository_owner}/*" => {'allowed' => true}}}))

    post '/', :payload => GITHUB_JSON.to_json

    last_response.should be_ok
    last_response.body.should == 'done'
  end

  pending 'should reply with fail message if repository is not allowed to be mirrored' do
    @app.stub!(:config).and_return(config({'repositories' => {"#{repository_owner}/#{repository_name}" => {'allowed' => false}}}))

    post '/', :payload => GITHUB_JSON.to_json

    last_response.should be_ok
    last_response.body.should =~ /fail:/
  end

  pending 'should reply with success message if repository is allowed to be mirrored' do
    @app.stub!(:config).and_return(config({'repositories' => {"#{repository_owner}/#{repository_name}" => {'allowed' => true}}}))

    post '/', :payload => GITHUB_JSON.to_json

    last_response.should be_ok
    last_response.body.should == 'done'
  end

end
