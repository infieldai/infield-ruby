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
          Thread.new { loop { event.wait.then { deliver }.then { event.reset } } }
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
          http = Net::HTTP.new(infield_api_uri.host, infield_api_uri.port)
          http.post('/api/raw_deprecation_warnings',
                    default_api_params.merge(message: task.message).to_json,
                    { 'Content-Type' => 'application/json', 'Authorization' => "bearer #{Infield.api_key}" })
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
        callstack ||= caller_locations(2)
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
