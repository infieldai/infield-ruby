# frozen_string_literal: true

module Infield
  # Takes in new deprecation warnings and sends them to the Infield API
  # in batches
  module DeprecationWarning
    Task = Struct.new(:message, :callstack)

    # Handles spinning up a thread to process work
    module Runner
      # The list of errors ::Net::HTTP is known to raise
      # See https://github.com/ruby/ruby/blob/b0c639f249165d759596f9579fa985cb30533de6/lib/bundler/fetcher.rb#L281-L286
      HTTP_ERRORS = [
        Timeout::Error, EOFError, SocketError, Errno::ENETDOWN, Errno::ENETUNREACH,
        Errno::EINVAL, Errno::ECONNRESET, Errno::ETIMEDOUT, Errno::EAGAIN,
        Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError,
        Zlib::BufError, Errno::EHOSTUNREACH, Errno::ECONNREFUSED
      ].freeze

      class << self
        attr_reader :queue, :thread

        def enqueue(message)
          @queue ||= Queue.new
          return if @queue.size >= @queue_limit
          @queue << message
        end

        def run(sleep_interval: 5, batch_size: 10, queue_limit: 30)
          @queue ||= Queue.new
          @sleep_interval = sleep_interval
          # Queue cannot be larger than this. If more than this number of messages come in
          # before the next wake interval any extra are dropped
          @queue_limit = queue_limit
          @batch_size = batch_size # send up to 20 messages to API at once

          @thread = Thread.new do
            loop do
              sleep(@sleep_interval)
              next if @queue.empty?

              process_queue
            end
          end
        end

        def post_deprecation_warnings(tasks)
          messages = tasks.map { |w| { message: w.message, callstack: w.callstack.map(&:to_s) } }

          uri = infield_api_uri

          webmock_needs_re_enabling = false
          if defined?(WebMock) && WebMock.respond_to?(:net_connect_allowed?) &&
             !WebMock.net_connect_allowed?(Infield.infield_api_url)
            webmock_needs_re_enabling = true
            allowed = WebMock::Config.instance.allow
            WebMock.disable_net_connect!(allow: Infield.infield_api_url)
          end

          if defined?(Rails) && Rails.respond_to?(:root)
            rails_root = Rails.root.to_s
          end

          Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
            http.post('/api/raw_deprecation_warnings',
                      { raw_deprecation_warnings: {
                          repo_environment_id: Infield.repo_environment_id,
                          environment: Infield.environment,
                          root_dir: rails_root,
                          messages: messages
                        }
                      }.to_json,
                      { 'Content-Type' => 'application/json', 'Authorization' => "bearer #{Infield.api_key}" })
          end
        rescue *HTTP_ERRORS => e
        ensure
          if webmock_needs_re_enabling
            WebMock.disable_net_connect!(allow: allowed)
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
      end
    end

    class << self
      def log(*messages, callstack: nil, validated: false)
        messages = messages.select(&method(:valid_message)) unless validated
        messages.each { |message| Runner.enqueue(Task.new(message, callstack)) }
        true
      end

      private

      def valid_message(message)
        message =~ /(?:^|\W)deprecated(?:$|\W)/i
      end
    end
  end
end
