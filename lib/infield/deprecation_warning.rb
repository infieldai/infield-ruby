# frozen_string_literal: true

require 'concurrent/array'
require 'concurrent/atomic/event'
require 'net/http'

module Infield
  module DeprecationWarning
    Task = Struct.new(:message, :callstack)

    module Runner
      class << self
        def event
          @event ||= Concurrent::Event.new
        end

        def tasks
          @tasks ||= Concurrent::Array.new
        end

        def run
          Thread.new do
            loop do
              event.wait
              deliver
              event.reset
            end
          end
        end

        private

        def default_api_params
          { repo_environment_id: Infield.repo_environment_id,
            environment: Infield.environment }
        end

        def infield_api_uri
          URI.parse(Infield.infield_api_url)
        end

        def upload_message(task)
          uri = infield_api_uri
          Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
            http.post('/api/raw_deprecation_warnings',
                      default_api_params.merge(message: task.message).to_json,
                      { 'Content-Type' => 'application/json', 'Authorization' => "bearer #{Infield.api_key}" })
          end
        end

        def deliver
          while (task = tasks.shift)
            upload_message(task)
          end
        end
      end
    end

    class << self
      def log(*messages, callstack: nil, validated: false)
        messages = messages.select(&method(:valid_message)) unless validated
        messages.each { |message| tasks << Task.new(message, callstack) }
        Runner.event.set
      end

      private

      delegate :tasks, to: 'Infield::DeprecationWarning::Runner'

      def valid_message(message)
        message =~ /(?:^|\W)deprecated(?:$|\W)/i
      end
    end
  end
end
