# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

describe_current do
  let(:manager) { described_class.send(:new) }

  describe "#on_app_running" do
    before { manager.stubs(:async_call) }

    it "expect to start listening for commands asynchronously" do
      manager.expects(:async_call).with("karafka.web.pro.commanding.manager")
      manager.on_app_running(nil)
    end
  end

  describe "#on_app_stopping" do
    let(:listener) { Karafka::Web::Pro::Commanding::Listener.new }

    before do
      listener.class.stubs(:new).returns(listener)
      listener.stubs(:stop)
    end

    it "expect to stop the listener" do
      listener.expects(:stop)
      manager.on_app_stopping(nil)
    end
  end

  describe "#on_app_stopped" do
    it "calls the method without errors" do
      # Just ensure the method can be called without raising errors
      # We cannot test thread joining without accessing internal state
      manager.on_app_stopped(nil)
    end
  end

  describe "integration with commands" do
    let(:listener) { Karafka::Web::Pro::Commanding::Listener.new }
    let(:matcher) { Karafka::Web::Pro::Commanding::Matcher.new }
    let(:unsupported_command_name) { "unsupported_command" }

    let(:msg) do
      stub(payload: {
        command: {
          name: command_name
        }
      })
    end

    before do
      listener.class.stubs(:new).returns(listener)
      matcher.class.stubs(:new).returns(matcher)
      listener.stubs(:each).yields(msg)
      matcher.stubs(:matches?).with(msg).returns(true)
    end

    context "when command is trace" do
      let(:trace_command) { Karafka::Web::Pro::Commanding::Commands::Consumers::Trace.new({}) }
      let(:command_name) { trace_command.class.name }

      before do
        trace_command.class.stubs(:new).returns(trace_command)
        trace_command.stubs(:call)
      end

      it "executes trace command" do
        trace_command.expects(:call)
        manager.send(:call)
      end
    end

    context "when command is quiet" do
      let(:quiet_command) { Karafka::Web::Pro::Commanding::Commands::Consumers::Quiet.new({}) }
      let(:command_name) { quiet_command.class.name }

      before do
        quiet_command.class.stubs(:new).returns(quiet_command)
        quiet_command.stubs(:call)
      end

      it "executes quiet command" do
        quiet_command.expects(:call)
        manager.send(:call)
      end
    end

    context "when command is stop" do
      let(:stop_command) { Karafka::Web::Pro::Commanding::Commands::Consumers::Stop.new({}) }
      let(:command_name) { stop_command.class.name }

      before do
        stop_command.class.stubs(:new).returns(stop_command)
        stop_command.stubs(:call)
      end

      it "executes stop command" do
        stop_command.expects(:call)
        manager.send(:call)
      end
    end

    context "when command is seek" do
      let(:seek_command) { Karafka::Web::Pro::Commanding::Commands::Partitions::Seek.new({}) }
      let(:command_name) { seek_command.class.name }

      before do
        seek_command.class.stubs(:new).returns(seek_command)
        seek_command.stubs(:call)
      end

      it "executes stop command" do
        seek_command.expects(:call)
        manager.send(:call)
      end
    end

    context "when command is pause" do
      let(:pause_command) { Karafka::Web::Pro::Commanding::Commands::Partitions::Pause.new({}) }
      let(:command_name) { pause_command.class.name }

      before do
        pause_command.class.stubs(:new).returns(pause_command)
        pause_command.stubs(:call)
      end

      it "executes stop command" do
        pause_command.expects(:call)
        manager.send(:call)
      end
    end

    context "when command is resume" do
      let(:resume_command) { Karafka::Web::Pro::Commanding::Commands::Partitions::Resume.new({}) }
      let(:command_name) { resume_command.class.name }

      before do
        resume_command.class.stubs(:new).returns(resume_command)
        resume_command.stubs(:call)
      end

      it "executes stop command" do
        resume_command.expects(:call)
        manager.send(:call)
      end
    end

    context "when command is unsupported" do
      let(:command_name) { unsupported_command_name }

      it "raises UnsupportedCaseError" do
        assert_raises(Karafka::Errors::UnsupportedCaseError) { manager.send(:call) }
      end
    end
  end
end
