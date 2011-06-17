# encoding: utf-8
require 'singleton'

class GithubMirror
  class Config
    include Singleton

    def self.config
      instance
    end

    def self.load(config)
      instance.load(config)
    end

    protected

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

    end
  end
end
