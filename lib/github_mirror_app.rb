require 'rack'
require 'json'

class GithubMirrorApp

  class GithubMirrorError < StandardError; end

  def call(env)
    @request  = Rack::Request.new(env)
    @response = Rack::Response.new

    handle_request

    @response.finish
  end

  private

  def config
    @config ||= YAML.load_file(File.expand_path('../../config/config.yaml', __FILE__))
  end

  def handle_request
    raise GithubMirrorError, 'Only POST request allowed' unless @request.post? # return fail message if request is not a POST

    payload = JSON.parse(@request[:payload]) rescue raise(GithubMirrorError, 'Payload param need to be present and a valid JSON string')

    # get informations about repository
    repository_owner   = payload['repository']['owner']['name'] rescue raise(GithubMirrorError, 'Repository owner name required')
    repository_name    = payload['repository']['name']          rescue raise(GithubMirrorError, 'Repository name required')

    repository_private = payload['repository']['private'] == '1' ? true : false

    # generate url (for private or public project)
    if repository_private
      repository_url = "git@github.com:#{repository_owner}/#{repository_name}.git"
    else
      repository_url = "git://github.com/#{repository_owner}/#{repository_name}.git"
    end

    # get mirror configuration for current repository
    mirror_config = config['mirrors']["#{repository_owner}/#{repository_name}"] || config['mirrors']['default']

    mirror_path   = File.join(mirror_config['root'], "#{repository_name}.git")

    # clone repository if mirror doesn't exist
    unless File.exist?(mirror_path)
      system("git clone --mirror --origin github_mirroring #{repository_url} #{mirror_path}")

    # fetch repository if mirror already exist
    else
      if `cd #{mirror_path}; git remote` !~ /github_mirroring/
        system("cd #{mirror_path}; git remote add --mirror github_mirroring #{repository_url}")
      end
      system("cd #{mirror_path}; git fetch github_mirroring")
    end

    # end
    @response.write 'done'
  rescue GithubMirrorError
    @response.write 'fail'
  end
end