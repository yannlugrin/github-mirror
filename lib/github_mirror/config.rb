# encoding: utf-8
require 'singleton'

class GithubMirror
  class Config
    include Singleton

    def initialize
      @repositories_config = {}
    end

    def self.config
      instance
    end

    def self.load(config)
      instance.load(config)
    end

    def self.token
      instance.token
    end

    attr_reader :token

    def self.repository_info(repository_owner, repository_name)
      instance.repository_info(repository_owner, repository_name)
    end

    # Return an object with reader method for allowed, path and patterns
    # attributes builded from configuration file.
    #
    # Merge from configuration file in following order:
    # - repository_owner/repository_name
    # - repository_owner/repository_name*
    # - repository_owner/*
    # - repository_owner/*
    # - repository_owner*/*
    # - */*
    def repository_info(repository_owner, repository_name)
      if @repository_info.nil?
        @repository_info = {}

        @repository_info.default_proc = proc {|hash, repository|
          hash[repository] = RepositoryInfo.new(false, File.expand_path('./repositories'), {})

          matches = @repositories_config.select do |pattern, value|
            repository =~ /^#{ pattern.gsub(/^([^\/]+\/)??\*+/, '\1[^/]+').gsub(/\*+/, '[^/]*') }$/
          end
          exact_match = matches.delete(repository) || {}

          hash[repository].members.each do |key|
            (matches.sort {|a, b| a.first <=> b.first }.map {|v| v.last} + [exact_match]).each do |match|
              hash[repository][key] = match[key.to_s] if match.has_key?(key.to_s) && !match[key.to_s].nil?
            end
          end
          hash[repository].freeze

          hash[repository]
        }
      end

      @repository_info["#{repository_owner}/#{repository_name}"]
    end
    RepositoryInfo = Struct.new(:allowed, :path, :patterns)

    def load(config)
      # load from YAML file
      if config.is_a?(String)
        config_path = File.expand_path(config)
        raise(ArgumentError, "file must exist (#{config_path})") unless File.exist?(config_path)
        config = YAML.load_file(config_path)
        raise(ArgumentError, "file content must be a Hash (#{config_path})") unless config.is_a?(Hash)
      # or check if is a Hash
      else
        raise(ArgumentError, 'must be a valid file path or Hash') unless config.is_a?(Hash)
      end

      # set token value
      @token = !config['token'].to_s.strip.empty? ? config['token'].to_s.strip.freeze : nil

      # set repositories configuration
      @repositories_config = config['repositories'].is_a?(Hash) ? config['repositories'].freeze : {}
      @repository_info = nil # reset to be reloaded from config on next access

      self
    end
  end
end
