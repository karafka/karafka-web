# frozen_string_literal: true

RSpec.describe_current do
  subject(:probe_command) { described_class.new }

  let(:dispatcher) { Karafka::Web::Pro::Commanding::Dispatcher }
  let(:test_thread) { Thread.new { sleep(0.5) } }
  let(:mock_pid) { 12_345 }

  before do
    allow(dispatcher).to receive(:result)
    allow(::Process).to receive(:pid).and_return(mock_pid)
    sleep(0.05)
  end

  after do
    test_thread.kill
    test_thread.join
  end

  it 'expect to collect and publish threads backtraces to Kafka' do
    probe_command.call

    expect(dispatcher).to have_received(:result) do |threads_info, pid, action|
      expect(threads_info).to be_a(Hash)
      expect(pid).to include(mock_pid.to_s)
      expect(action).to eq('probe')

      thread_info = threads_info.values.first
      expect(thread_info[:label]).to include('Thread TID-')
      expect(thread_info[:backtrace]).to be_a(String)
    end
  end

  context 'when process to which we send request is an embedded one' do
    before { allow(Karafka::Process).to receive(:tags).and_return(%w[embedded]) }

    it 'expect to handle it without any issues' do
      probe_command.call

      expect(dispatcher).to have_received(:result) do |threads_info, pid, action|
        expect(threads_info).to be_a(Hash)
        expect(pid).to include(mock_pid.to_s)
        expect(action).to eq('probe')

        thread_info = threads_info.values.first
        expect(thread_info[:label]).to include('Thread TID-')
        expect(thread_info[:backtrace]).to be_a(String)
      end
    end
  end
end
