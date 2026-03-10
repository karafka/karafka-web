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

describe_current do
  let(:executor) { described_class.new }

  let(:listener) { stub }
  let(:client) { stub }
  let(:request) { stub }

  describe "#call" do
    context "when command is resume" do
      let(:command_name) { Karafka::Web::Pro::Commanding::Commands::Partitions::Resume.name }
      let(:command_class) { Karafka::Web::Pro::Commanding::Handlers::Partitions::Commands::Resume }
      let(:command_instance) { stub }

      before do
        request.stubs(:name).returns(command_name)
        command_instance.stubs(:call)
        command_class.stubs(:new).returns(command_instance)
      end

      it "executes resume command" do
        command_class.expects(:new).with(listener, client, request).returns(command_instance)
        command_instance.expects(:call)
        executor.call(listener, client, request)
      end
    end

    context "when command is pause" do
      let(:command_name) { Karafka::Web::Pro::Commanding::Commands::Partitions::Pause.name }
      let(:command_class) { Karafka::Web::Pro::Commanding::Handlers::Partitions::Commands::Pause }
      let(:command_instance) { stub }

      before do
        request.stubs(:name).returns(command_name)
        command_instance.stubs(:call)
        command_class.stubs(:new).returns(command_instance)
      end

      it "executes pause command" do
        command_class.expects(:new).with(listener, client, request).returns(command_instance)
        command_instance.expects(:call)
        executor.call(listener, client, request)
      end
    end

    context "when command is seek" do
      let(:command_name) { Karafka::Web::Pro::Commanding::Commands::Partitions::Seek.name }
      let(:command_class) { Karafka::Web::Pro::Commanding::Handlers::Partitions::Commands::Seek }
      let(:command_instance) { stub }

      before do
        request.stubs(:name).returns(command_name)
        command_instance.stubs(:call)
        command_class.stubs(:new).returns(command_instance)
      end

      it "executes seek command" do
        command_class.expects(:new).with(listener, client, request).returns(command_instance)
        command_instance.expects(:call)
        executor.call(listener, client, request)
      end
    end

    context "when command is not supported" do
      let(:command_name) { "unsupported.command" }

      before do
        request.stubs(:name).returns(command_name)
      end

      it "raises UnsupportedCaseError" do
        assert_raises(Karafka::Errors::UnsupportedCaseError) { executor.call(listener, client, request) }
      end
    end
  end

  describe "#reject" do
    let(:command_name) { "test.command" }
    let(:request_hash) { { key: "value" } }
    let(:sampler) { Karafka::Web.config.tracking.consumers.sampler }

    before do
      request.stubs(:name).returns(command_name)
      request.stubs(:to_h).returns(request_hash)
      Karafka::Web::Pro::Commanding::Dispatcher.stubs(:result)
    end

    it "dispatches rejection result with rebalance status" do
      expected_payload = request_hash.merge(status: "rebalance_rejected")
      Karafka::Web::Pro::Commanding::Dispatcher.expects(:result).with(command_name, sampler.process_id, expected_payload)
      executor.reject(request)
    end
  end
end
