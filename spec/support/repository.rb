# encoding: utf-8

def stub_repository_info(attrs = {})
    attrs = [attrs] unless attrs.is_a?(Array)
    attrs.map! do |a|
      GithubMirror::Config::RepositoryInfo.new(
        a[:allowed]  || false,
        a[:path]     || File.expand_path('./repositories'),
        a[:patterns] || {}
      )
    end
  GithubMirror::Config.stub!(:repository_info).and_return(*attrs)
end

def repository_owner(repository_owner = nil)
  GITHUB_JSON['repository']['owner']['name'] = repository_owner if repository_owner
  GITHUB_JSON['repository']['owner']['name']
end

def repository_name(repository_name = nil)
  GITHUB_JSON['repository']['name'] = repository_name if repository_name
  GITHUB_JSON['repository']['name']
end

def repository_private(repository_private = nil)
  GITHUB_JSON['repository']['private'] = (repository_private ? '1' : nil) if repository_private
  GITHUB_JSON['repository']['private'] == '1' ? true : false
end

def repository_url
  GITHUB_JSON['repository']['private'] = repository_private ? '1' : '0'

  if repository_private
    "git@github.com:#{repository_owner}/#{repository_name}.git"
  else
    "git://github.com/#{repository_owner}/#{repository_name}.git"
  end
end

def mirror_path(repository_name = repository_name)
  File.join(File.expand_path('../../fixtures/mirrors_root', __FILE__), "#{repository_owner}/#{repository_name}.git")
end

def config(override = {})
  config = {
    'repositories' => {
      '*/*' => {
        'allowed' => true,
        'path'    => File.expand_path('../../fixtures/mirrors_root', __FILE__)
      }
    }
  }
  config['repositories'].merge!(override.delete('repositories') || {})
  config.merge!(override)
  config
end
