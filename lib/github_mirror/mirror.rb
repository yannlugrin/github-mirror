# encoding: utf-8

class GithubMirror
  class Mirror

    attr_reader :owner
    attr_reader :name

    def initialize(owner, name)
      raise(ArgumentError, 'owner attribute can\'t be empty') if owner.nil? || !owner.is_a?(String) || owner.empty?
      raise(ArgumentError, 'name attribute can\'t be empty')  if name.nil?  || !name.is_a?(String)  || name.empty?

      @owner, @name = owner, name
    end

    def path
      @path ||= lambda do
        path     = GithubMirror::Config.repository_info("#{owner}/#{name}").path
        patterns = GithubMirror::Config.repository_info("#{owner}/#{name}").patterns

        keys = path.scan(/:(\w+)/).flatten
        unless keys.empty?
          keys.each do |key|
            if key == 'repository_name' && !patterns.has_key?('repository_name')
              value = name
            elsif key == 'repository_owner' && !patterns.has_key?('repository_owner')
              value = owner
            else
              value = name.match(patterns[key])[1]
            end
            path.gsub!(/:#{key}/, value)
          end
        else
          path = File.join(path, "#{owner}/#{name}.git")
        end
        path += '.git' unless path.match(/\.git$/)
        path
      end.call
    end

  end
end
