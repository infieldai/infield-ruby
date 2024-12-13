# frozen_string_literal: true

require 'webmock/rspec'

RSpec.describe Infield::Heartbeat::Runner do
  let(:heartbeat_interval) { 0.1 }
  let(:heartbeat_url) { "#{Infield.infield_api_url}/api/heartbeats" }
  let(:requests) { [] }

  before do
    Infield.api_key = 'test-key'
    Infield.repo_environment_id = 'test-repo'
    Infield.environment = 'test'
    Infield.infield_api_url = 'https://test.infield.ai'

    Infield::DeprecationWarning::Runner.run(sleep_interval: 0.1)

    stub_request(:post, heartbeat_url)
      .with(
        headers: {
          'Content-Type' => 'application/json',
          'Authorization' => "bearer #{Infield.api_key}"
        }
      )
      .to_return do |request|
        requests << JSON.parse(request.body)
        { status: 200, body: '' }
      end
  end

  after do
    described_class.stop
    Infield::DeprecationWarning::Runner.thread&.kill
    WebMock.reset!
  end

  it 'sends periodic heartbeats' do
    described_class.run(interval: heartbeat_interval)
    sleep(heartbeat_interval * 3)

    expect(requests.length).to be >= 2
    expect(requests.first).to include(
      'repo_environment_id' => Infield.repo_environment_id,
      'environment' => Infield.environment,
    )

    expect(WebMock).to have_requested(:post, heartbeat_url)
      .with(
        headers: {
          'Content-Type' => 'application/json',
          'Authorization' => "bearer #{Infield.api_key}"
        }
      )
      .at_least_times(2)
  end

  it 'stops when deprecation thread dies' do
    described_class.run(interval: heartbeat_interval)
    sleep(heartbeat_interval * 2)
    initial_count = requests.length

    Infield::DeprecationWarning::Runner.thread.kill
    sleep(heartbeat_interval * 3)

    expect(requests.length).to eq(initial_count)
    expect(described_class.thread.alive?).to be false
  end

  it 'handles network errors gracefully' do
    stub_request(:post, heartbeat_url).to_raise(Errno::ECONNREFUSED)

    expect {
      described_class.run(interval: heartbeat_interval)
      sleep(heartbeat_interval * 2)
    }.not_to raise_error
  end
end
