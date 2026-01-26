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
  subject(:manager) { described_class.send(:new) }

  describe "#on_app_running" do
    before { allow(manager).to receive(:async_call) }

    it "expect to start listening for commands asynchronously" do
      manager.on_app_running(nil)

      expect(manager).to have_received(:async_call).with("karafka.web.pro.commanding.manager")
    end
  end

  describe "#on_app_stopping" do
    let(:listener) { Karafka::Web::Pro::Commanding::Listener.new }

    before do
      allow(listener.class).to receive(:new).and_return(listener)
      allow(listener).to receive(:stop)
    end

    it "expect to stop the listener" do
      manager.on_app_stopping(nil)
      expect(listener).to have_received(:stop)
    end
  end

  describe "#on_app_stopped" do
    it "calls the method without errors" do
      # Just ensure the method can be called without raising errors
      # We cannot test thread joining without accessing internal state
      expect { manager.on_app_stopped(nil) }.not_to raise_error
    end
  end

  describe "integration with commands" do
    let(:listener) { Karafka::Web::Pro::Commanding::Listener.new }
    let(:matcher) { Karafka::Web::Pro::Commanding::Matcher.new }
    let(:unsupported_command_name) { "unsupported_command" }

    let(:message) do
      instance_double(
        Karafka::Messages::Message,
        payload: {
          command: {
            name: command_name
          }
        }
      )
    end

    before do
      allow(listener.class).to receive(:new).and_return(listener)
      allow(matcher.class).to receive(:new).and_return(matcher)
      allow(listener).to receive(:each).and_yield(message)
      allow(matcher).to receive(:matches?).with(message).and_return(true)
    end

    context "when command is trace" do
      let(:trace_command) { Karafka::Web::Pro::Commanding::Commands::Consumers::Trace.new({}) }
      let(:command_name) { trace_command.class.name }

      before do
        allow(trace_command.class).to receive(:new).and_return(trace_command)
        allow(trace_command).to receive(:call)
      end

      it "executes trace command" do
        manager.send(:call)
        expect(trace_command).to have_received(:call)
      end
    end

    context "when command is quiet" do
      let(:quiet_command) { Karafka::Web::Pro::Commanding::Commands::Consumers::Quiet.new({}) }
      let(:command_name) { quiet_command.class.name }

      before do
        allow(quiet_command.class).to receive(:new).and_return(quiet_command)
        allow(quiet_command).to receive(:call)
      end

      it "executes quiet command" do
        manager.send(:call)
        expect(quiet_command).to have_received(:call)
      end
    end

    context "when command is stop" do
      let(:stop_command) { Karafka::Web::Pro::Commanding::Commands::Consumers::Stop.new({}) }
      let(:command_name) { stop_command.class.name }

      before do
        allow(stop_command.class).to receive(:new).and_return(stop_command)
        allow(stop_command).to receive(:call)
      end

      it "executes stop command" do
        manager.send(:call)
        expect(stop_command).to have_received(:call)
      end
    end

    context "when command is seek" do
      let(:seek_command) { Karafka::Web::Pro::Commanding::Commands::Partitions::Seek.new({}) }
      let(:command_name) { seek_command.class.name }

      before do
        allow(seek_command.class).to receive(:new).and_return(seek_command)
        allow(seek_command).to receive(:call)
      end

      it "executes stop command" do
        manager.send(:call)
        expect(seek_command).to have_received(:call)
      end
    end

    context "when command is pause" do
      let(:pause_command) { Karafka::Web::Pro::Commanding::Commands::Partitions::Pause.new({}) }
      let(:command_name) { pause_command.class.name }

      before do
        allow(pause_command.class).to receive(:new).and_return(pause_command)
        allow(pause_command).to receive(:call)
      end

      it "executes stop command" do
        manager.send(:call)
        expect(pause_command).to have_received(:call)
      end
    end

    context "when command is resume" do
      let(:resume_command) { Karafka::Web::Pro::Commanding::Commands::Partitions::Resume.new({}) }
      let(:command_name) { resume_command.class.name }

      before do
        allow(resume_command.class).to receive(:new).and_return(resume_command)
        allow(resume_command).to receive(:call)
      end

      it "executes stop command" do
        manager.send(:call)
        expect(resume_command).to have_received(:call)
      end
    end

    context "when command is unsupported" do
      let(:command_name) { unsupported_command_name }

      it "raises UnsupportedCaseError" do
        expect { manager.send(:call) }.to raise_error(Karafka::Errors::UnsupportedCaseError)
      end
    end
  end
end
