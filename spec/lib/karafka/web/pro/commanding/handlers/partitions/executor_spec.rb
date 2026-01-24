# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

RSpec.describe_current do
  subject(:executor) { described_class.new }

  let(:listener) { instance_double(Karafka::Connection::Listener) }
  let(:client) { instance_double(Karafka::Connection::Client) }
  let(:request) { instance_double(Karafka::Web::Pro::Commanding::Request) }

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
    let(:sampler) { Karafka::Web.config.tracking.consumers.sampler }

    before do
      allow(request).to receive_messages(name: command_name, to_h: request_hash)
      allow(Karafka::Web::Pro::Commanding::Dispatcher).to receive(:result)
    end

    it 'dispatches rejection result with rebalance status' do
      executor.reject(request)

      expected_payload = request_hash.merge(status: 'rebalance_rejected')

      expect(Karafka::Web::Pro::Commanding::Dispatcher)
        .to have_received(:result)
        .with(command_name, sampler.process_id, expected_payload)
    end
  end
end
