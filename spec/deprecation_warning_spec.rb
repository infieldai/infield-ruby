# frozen_string_literal: true

RSpec.describe Infield::DeprecationWarning do
  let(:runner) { Infield::DeprecationWarning::Runner }
  let(:message_count) { 50 }
  let(:queue_limit) { 40 }
  let(:batch_size) { 20 }
  let(:sleep_interval) { 0.01 }
  let(:batches) { [] }
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
