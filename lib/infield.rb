# frozen_string_literal: true

require_relative 'infield/version'

# require_relative 'infield/core_ext'
require_relative 'infield/rails' if defined?(Rails)

module Infield
  Error = Class.new(StandardError)

  autoload :DeprecationWarning, "#{__dir__}/infield/deprecation_warning.rb"

  class << self
    attr_accessor :api_key, :repo_environment_id, :environment

    def run(api_key: nil, repo_environment_id: nil, environment: nil)
      @api_key = api_key || ENV['INFIELD_API_KEY']
      @repo_environment_id = repo_environment_id
      raise 'API key is required' unless @api_key
      raise 'repo_environment_id is required' unless @repo_environment_id

      @environment = environment || defined?(Rails) ? Rails.env : nil
      DeprecationWarning::Runner.run
    end
  end
end
