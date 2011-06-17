# encoding: utf-8
require 'json'

class GithubMirror
  class Rack
    def call(env)
      @request  = ::Rack::Request.new(env)
      @response = ::Rack::Response.new

      handle_request

      @response.finish
    end

    private

    def handle_request
      raise(ArgumentError, 'only POST request allowed') unless @request.post?
      raise(ArgumentError, 'token not match')           if config.token && !@request.path_info.end_with?('/' + config.token)

      payload = JSON.parse(@request[:payload])    rescue raise(ArgumentError, 'payload is not a valid JSON string')
      mirror  = Mirror.load_from_payload(payload) rescue raise(ArgumentError, 'payload is not a valid Github push')

      mirror.update

      @response.write 'done'
    rescue Exception => e
      @response.write "fail: #{e.message}"
    end

    def config
      GithubMirror::Config.config
    end
  end
end
