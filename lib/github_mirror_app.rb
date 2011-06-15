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

  def local_path(repository_owner, repository_name)
    mirror_config = config['mirrors']["#{repository_owner}/#{repository_name}"] || config['mirrors']['default']

    mirror_path     = mirror_config['path'] || raise(GithubMirrorError, "Path for repository '#{repository_owner}/#{repository_name}' don't exist in config")
    mirror_patterns = (mirror_config['patterns'] || {}).merge({'repository_name' => '^(.+)$'})

    keys = mirror_path.scan(/:(\w+)/).flatten
    unless keys.empty?
      keys.each do |key|
        if key == 'repository_owner' && !mirror_patterns.has_key?('repository_owner')
          value = repository_owner
        else
          value = repository_name.match(mirror_patterns[key])[1] rescue raise(GithubMirrorError, "Repository name pattern have an error for key `#{key}`: #{mirror_patterns[key] || 'no pattern'}")
        end
        mirror_path.gsub!(/:#{key}/, value)
      end
    else
      mirror_path = File.join(mirror_path, "#{repository_name}.git")
    end
    mirror_path += '.git' unless mirror_path.match(/\.git$/)

    mirror_path
  end

  def handle_request
    raise GithubMirrorError, 'Only POST request allowed' unless @request.post? # return fail message if request is not a POST

    payload = JSON.parse(@request[:payload]) rescue raise(GithubMirrorError, 'Payload param need to be present and a valid JSON string')

    # get informations about repository
    repository_owner   = payload['repository']['owner']['name'] rescue raise(GithubMirrorError, 'Repository owner name required')
    repository_name    = payload['repository']['name']          rescue raise(GithubMirrorError, 'Repository name required')

    repository_private = payload['repository']['private'] == '1' ? true : false

    # check if repository can be mirrored
    unless (config['allowed'] || ['*/*']).any? {|allowed_pattern| "#{repository_owner}/#{repository_name}" =~ /^#{allowed_pattern.gsub(/\*+/, '[^/]+')}$/ }
      raise(GithubMirrorError, "Repository #{repository_owner}/#{repository_name} is not allowed to be mirrored")
    end

    # generate url (for private or public project)
    if repository_private
      repository_url = "git@github.com:.git"
    else
      repository_url = "git://github.com/#{repository_owner}/#{repository_name}.git"
    end

    # get mirror path
    repository_path = local_path(repository_owner, repository_name)

    # clone repository if mirror doesn't exist
    unless File.exist?(repository_path)
      system("git clone --mirror --origin github_mirroring #{repository_url} #{repository_path}")

    # fetch repository if mirror already exist
    else
      if `cd #{repository_path}; git remote` !~ /github_mirroring/
        system("cd #{repository_path}; git remote add --mirror github_mirroring #{repository_url}")
      end
      system("cd #{repository_path}; git fetch github_mirroring")
    end

    # end
    @response.write 'done'
  rescue GithubMirrorError => e
    @response.write "fail: #{e.message}"
  end
end