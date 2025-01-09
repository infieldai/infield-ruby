# frozen_string_literal: true

module Infield
  module Heartbeat
    module Runner
      class << self
        attr_reader :thread

        def run(interval: 60)
          @thread = Thread.new do
            loop do
              if DeprecationWarning::Runner.thread&.alive?
                send_heartbeat
              else
                stop
                break
              end
              sleep(interval)
            end
          end
        end

        def stop
          @thread&.kill
        end

        private

        def send_heartbeat
          uri = URI.parse(Infield.infield_api_url)
          Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
            http.post('/api/heartbeats',
                    {
                      repo_environment_id: Infield.repo_environment_id,
                      environment: Infield.environment,
                    }.to_json,
                    {
                      'Content-Type' => 'application/json',
                      'Authorization' => "bearer #{Infield.api_key}"
                    })
          end
        rescue *DeprecationWarning::Runner::HTTP_ERRORS => e
        end
      end
    end
  end
end
