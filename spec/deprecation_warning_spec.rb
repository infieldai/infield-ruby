# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Infield::DeprecationWarning do
  let(:runner) { Infield::DeprecationWarning::Runner }
  let(:message_count) { 50 }
  let(:queue_limit) { 40 }
  let(:batch_size) { 20 }
  let(:sleep_interval) { 0.01 }
  let(:batches) { [] }

  describe 'logging behavior' do
    before do
      allow(runner).to receive(:post_deprecation_warnings) { |b| batches << b }
    end

    it 'can enqueue logs' do
      messages = (1..message_count).map { |i| "DEPRECATION WARNING: #{i} is going away" }
      runner.run(batch_size: batch_size, sleep_interval: sleep_interval, queue_limit: queue_limit)
      messages.each do |message|
        Infield::DeprecationWarning.log(message, validated: true)
      end
      sleep(sleep_interval * 2)
      expect(runner).to have_received(:post_deprecation_warnings).at_least(:once)
      expect(batches.size).to eq(2)
      expect(batches.flatten.size).to eq(queue_limit)
    end
  end

  describe Infield::DeprecationWarning::Runner do
    describe '.post_deprecation_warnings' do
      let(:message) { "DEPRECATION WARNING: ActionDispatch::IllegalStateError is deprecated without replacement." }
      let(:callstack) do
        [
          "(eval):1:in `<main>'",
          "/path/to/irb/completion.rb:414:in `eval'",
          "/path/to/irb/completion.rb:414:in `retrieve_completion_data'",
          "/path/to/irb/completion.rb:221:in `completion_candidates'"
        ]
      end
      let(:task) { Infield::DeprecationWarning::Task.new(message, callstack) }

      before do
        allow(Infield).to receive(:repo_environment_id).and_return('test-repo-id')
        allow(Infield).to receive(:environment).and_return('test')
        allow(Infield).to receive(:infield_api_url).and_return('https://api.infield.com')
        allow(Infield).to receive(:api_key).and_return('test-api-key')

        stub_request(:post, "https://api.infield.com/api/raw_deprecation_warnings")
          .with(
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'bearer test-api-key'
            },
            body: {
              raw_deprecation_warnings: {
                repo_environment_id: 'test-repo-id',
                environment: 'test',
                messages: [
                  {
                    message: message,
                    callstack: callstack.map(&:to_s)
                  }
                ]
              }
            }.to_json
          )
          .to_return(status: 200)
      end

      it 'sends the deprecation warning to the Infield API' do
        described_class.post_deprecation_warnings([task])
        assert_requested(:post, "https://api.infield.com/api/raw_deprecation_warnings", times: 1)
      end

      it 'handles HTTP errors gracefully' do
        stub_request(:post, "https://api.infield.com/api/raw_deprecation_warnings").to_timeout

        expect {
          described_class.post_deprecation_warnings([task])
        }.not_to raise_error
      end
    end
  end
end
