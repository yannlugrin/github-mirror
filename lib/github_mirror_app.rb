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

  def config(repository_owner, repository_name, reload = false)
    if @loaded_config.nil? || reload
      @loaded_config = YAML.load_file(File.expand_path('../../config/config.yml', __FILE__))

      @config = {}
      @config.default_proc = proc {|hash, repository|
        hash[repository] = Struct.new(:allowed, :path, :patterns).new(false, nil, {})

        matches = @loaded_config.select do |pattern, value|
          repository =~ /^#{ pattern.gsub(/^([^\/]+\/)??\*+/, '\1[^/]+').gsub(/\*+/, '[^/]*') }$/
        end
        exact_match = matches.delete(repository) || {}

        hash[repository].members.each do |key|
          matches.sort {|a, b| a.first <=> b.first }.map {|v| v.last}.each do |match|
            hash[repository][key] = match[key.to_s] if match.has_key?(key.to_s) && !match[key.to_s].nil?
          end
          hash[repository][key] = exact_match[key.to_s] if exact_match.has_key?(key.to_s) && !exact_match[key.to_s].nil?
        end

        hash[repository]
      }
    end

    @config["#{repository_owner}/#{repository_name}"]
  end

  def local_path(repository_owner, repository_name)
    mirror_path = config(repository_owner, repository_name).path || raise(GithubMirrorError, "Path for repository '#{repository_owner}/#{repository_name}' don't exist in config")
    mirror_patterns = config(repository_owner, repository_name).patterns

    keys = mirror_path.scan(/:(\w+)/).flatten
    unless keys.empty?
      keys.each do |key|
        if key == 'repository_name' && !mirror_patterns.has_key?('repository_name')
          value = repository_name
        elsif key == 'repository_owner' && !mirror_patterns.has_key?('repository_owner')
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
    unless config(repository_owner, repository_name).allowed
      raise(GithubMirrorError, "Repository #{repository_owner}/#{repository_name} is not allowed to be mirrored")
    end

    # generate url (for private or public project)
    if repository_private
      repository_url = "git@github.com:#{repository_owner}/#{repository_name}.git"
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