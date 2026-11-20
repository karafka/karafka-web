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
  include described_class

  let(:process) { Struct.new(:execution_mode, :status, :tags).new("standalone", "running", []) }

  describe "#commanding_disabled_reason" do
    it { assert_nil(commanding_disabled_reason) }

    context "when commanding is off" do
      before { Karafka::Web.config.commanding.active = false }

      after { Karafka::Web.config.commanding.active = true }

      it { assert_equal("Commanding is disabled in the Web UI configuration", commanding_disabled_reason) }
    end
  end

  describe "#topics_management_disabled_reason" do
    it { assert_nil(topics_management_disabled_reason) }

    context "when topics management is off" do
      before { Karafka::Web.config.ui.topics.management.active = false }

      after { Karafka::Web.config.ui.topics.management.active = true }

      it do
        assert_equal(
          "Topics management is disabled in the Web UI configuration",
          topics_management_disabled_reason
        )
      end
    end
  end

  describe "#process_command_disabled_reason" do
    context "when a standalone process is running" do
      it "expect all the commands to be available" do
        assert_nil(process_command_disabled_reason(process, :trace))
        assert_nil(process_command_disabled_reason(process, :quiet))
        assert_nil(process_command_disabled_reason(process, :stop))
      end
    end

    context "when the process is stopped" do
      before { process.status = "stopped" }

      it "expect each command to explain the process state" do
        assert_equal("This process is stopped", process_command_disabled_reason(process, :trace))
        assert_equal(
          "Only a running process can be quieted",
          process_command_disabled_reason(process, :quiet)
        )
        assert_equal(
          "This process is already stopping or stopped",
          process_command_disabled_reason(process, :stop)
        )
      end
    end

    context "when the process is not standalone" do
      before { process.execution_mode = "swarm" }

      it "expect quiet and stop to be unsupported and trace to be available" do
        assert_nil(process_command_disabled_reason(process, :trace))
        assert_equal(
          "Supported only in standalone consumer processes",
          process_command_disabled_reason(process, :quiet)
        )
        assert_equal(
          "Supported only in standalone consumer processes",
          process_command_disabled_reason(process, :stop)
        )
      end
    end

    context "when the process is embedded" do
      before { process.tags = ["embedded"] }

      it do
        assert_equal(
          "Supported only in standalone consumer processes",
          process_command_disabled_reason(process, :stop)
        )
      end
    end

    context "when commanding is off and the process is not standalone" do
      before do
        Karafka::Web.config.commanding.active = false
        process.execution_mode = "swarm"
      end

      after { Karafka::Web.config.commanding.active = true }

      it "expect commanding being off to win" do
        assert_equal(
          "Commanding is disabled in the Web UI configuration",
          process_command_disabled_reason(process, :quiet)
        )
      end
    end

    context "when the command is unknown" do
      it do
        assert_raises(Karafka::Errors::UnsupportedCaseError) do
          process_command_disabled_reason(process, :unknown)
        end
      end
    end
  end
end
