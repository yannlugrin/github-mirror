require 'rack'
require 'json'

class GithubMirrorApp

  def call(env)
    @request  = Rack::Request.new(env)
    @response = Rack::Response.new

    handle_request

    @response.finish
  end

  private

  def handle_request
    raise 'Only POST request allowed' unless @request.post? # return fail message if request is not a POST

    payload = JSON.parse(@request[:payload])

    @response.write 'done'
  rescue
    @response.write 'fail'
  end
end