# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:executor) { described_class.new }

  let(:listener) { instance_double(Karafka::Connection::Listener) }
  let(:client) { instance_double(Karafka::Connection::Client) }
  let(:request) { instance_double(Karafka::Web::Pro::Commanding::Request) }
  let(:process_id) { SecureRandom.uuid }

  describe '#call' do
    context 'when command is resume' do
      let(:command_name) { Karafka::Web::Pro::Commanding::Commands::Partitions::Resume.name }
      let(:command_class) { Karafka::Web::Pro::Commanding::Handlers::Partitions::Commands::Resume }
      let(:command_instance) { instance_double(command_class) }

      before do
        allow(request).to receive(:name).and_return(command_name)
        allow(command_instance).to receive(:call)
        allow(command_class).to receive(:new).and_return(command_instance)
      end

      it 'executes resume command' do
        executor.call(listener, client, request)

        expect(command_class).to have_received(:new).with(listener, client, request)
        expect(command_instance).to have_received(:call)
      end
    end

    context 'when command is pause' do
      let(:command_name) { Karafka::Web::Pro::Commanding::Commands::Partitions::Pause.name }
      let(:command_class) { Karafka::Web::Pro::Commanding::Handlers::Partitions::Commands::Pause }
      let(:command_instance) { instance_double(command_class) }

      before do
        allow(request).to receive(:name).and_return(command_name)
        allow(command_instance).to receive(:call)
        allow(command_class).to receive(:new).and_return(command_instance)
      end

      it 'executes pause command' do
        executor.call(listener, client, request)

        expect(command_class).to have_received(:new).with(listener, client, request)
        expect(command_instance).to have_received(:call)
      end
    end

    context 'when command is seek' do
      let(:command_name) { Karafka::Web::Pro::Commanding::Commands::Partitions::Seek.name }
      let(:command_class) { Karafka::Web::Pro::Commanding::Handlers::Partitions::Commands::Seek }
      let(:command_instance) { instance_double(command_class) }

      before do
        allow(request).to receive(:name).and_return(command_name)
        allow(command_instance).to receive(:call)
        allow(command_class).to receive(:new).and_return(command_instance)
      end

      it 'executes seek command' do
        executor.call(listener, client, request)

        expect(command_class).to have_received(:new).with(listener, client, request)
        expect(command_instance).to have_received(:call)
      end
    end

    context 'when command is not supported' do
      let(:command_name) { 'unsupported.command' }

      before do
        allow(request).to receive(:name).and_return(command_name)
      end

      it 'raises UnsupportedCaseError' do
        expect { executor.call(listener, client, request) }
          .to raise_error(Karafka::Errors::UnsupportedCaseError)
      end
    end
  end

  describe '#reject' do
    let(:command_name) { 'test.command' }
    let(:request_hash) { { key: 'value' } }

    before do
      allow(request).to receive_messages(name: command_name, to_h: request_hash)
      allow(Karafka::Web::Pro::Commanding::Dispatcher).to receive(:result)
      allow(executor).to receive(:process_id).and_return(process_id)
    end

    it 'dispatches rejection result with rebalance status' do
      executor.reject(request)

      expected_payload = request_hash.merge(status: 'rebalance_rejected')

      expect(Karafka::Web::Pro::Commanding::Dispatcher)
        .to have_received(:result)
        .with(command_name, process_id, expected_payload)
    end
  end
end
