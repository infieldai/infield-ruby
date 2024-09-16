# frozen_string_literal: true

require_relative 'infield/version'

# require_relative 'infield/core_ext'
require_relative 'infield/rails' if defined?(Rails)

module Infield
  Error = Class.new(StandardError)

  autoload :DeprecationWarning, "#{__dir__}/infield/deprecation_warning.rb"

  class << self
    attr_accessor :api_key, :repo_environment_id, :environment, :infield_api_url

    def run(api_key: nil, repo_environment_id: nil, environment: nil, sleep_interval: 5, batch_size: 10, queue_limit: 30)
      @api_key = api_key || ENV['INFIELD_API_KEY']
      @repo_environment_id = repo_environment_id
      @infield_api_url = ENV['INFIELD_API_URL'] || 'https://app.infield.ai'
      raise 'API key is required' unless @api_key
      raise 'repo_environment_id is required' unless @repo_environment_id

      @environment = environment || defined?(Rails) ? Rails.env : nil
      DeprecationWarning::Runner.run(sleep_interval: sleep_interval, batch_size: batch_size, queue_limit: queue_limit)
    end
  end
end
