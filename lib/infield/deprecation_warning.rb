# frozen_string_literal: true

require 'thread'
require 'json'
require 'net/http'

module Infield
  # Takes in new deprecation warnings and sends them to the Infield API
  # in batches
  module DeprecationWarning
    Task = Struct.new(:message, :callstack)

    # Handles spinning up a thread to process work
    module Runner
      class << self
        attr_reader :queue

        def run(sleep_interval: 1, batch_size: 20)
          @queue ||= Queue.new
          @sleep_interval = sleep_interval
          @batch_size = batch_size # send up to 20 messages to API at once

          Thread.new do
            loop do
              sleep(@sleep_interval)
              next if @queue.empty?

              process_queue
            end
          end
        end

        private

        def process_queue
          messages = []
          messages << @queue.pop until @queue.empty?
          messages.each_slice(@batch_size) do |batch|
            post_deprecation_warnings(batch)
          end
        end

        def default_api_params
          { repo_environment_id: Infield.repo_environment_id,
            environment: Infield.environment }
        end

        def infield_api_uri
          URI.parse(Infield.infield_api_url)
        end

        def post_deprecation_warnings(tasks)
          messages = tasks.map { |w| { message: w.message } }
          uri = infield_api_uri
          Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
            http.post('/api/raw_deprecation_warnings',
                      default_api_params.merge(messages: messages).to_json,
                      { 'Content-Type' => 'application/json', 'Authorization' => "bearer #{Infield.api_key}" })
          end
        end
      end
    end

    class << self
      def log(*messages, callstack: nil, validated: false)
        messages = messages.select(&method(:valid_message)) unless validated
        messages.each { |message| Runner.queue << Task.new(message, callstack) }
        true
      end

      private

      def valid_message(message)
        message =~ /(?:^|\W)deprecated(?:$|\W)/i
      end
    end
  end
end
