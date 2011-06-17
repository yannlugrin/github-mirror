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

  end
end
