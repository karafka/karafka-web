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
  let(:command) { described_class.new(listener, client, request) }

  let(:listener) { stub }
  let(:client) { stub }

  let(:request) do
    Karafka::Web::Pro::Commanding::Request.new(
      reset_attempts: should_reset_attempts
    )
  end

  let(:coordinators) { stub }
  let(:coordinator) { stub }
  let(:pause_tracker) { stub }
  let(:topic) { "topic_name" }
  let(:partition_id) { 1 }
  let(:should_reset_attempts) { false }

  before do
    listener.stubs(:coordinators).returns(coordinators)

    coordinators.stubs(:find_or_create).with(topic, partition_id).returns(coordinator)

    coordinator.stubs(:pause_tracker).returns(pause_tracker)
    pause_tracker.stubs(:expire)
    pause_tracker.stubs(:reset)
    command.stubs(:topic).returns(topic)
    command.stubs(:partition_id).returns(partition_id)
    command.stubs(:result).returns(nil)
  end

  describe "#call" do
    context "when reset_attempts is false" do
      let(:should_reset_attempts) { false }

      it "expires the pause without resetting attempts" do
        pause_tracker.expects(:expire)
        pause_tracker.expects(:reset).never
        command.expects(:result).with("applied")
        command.call
      end
    end

    context "when reset_attempts is true" do
      let(:should_reset_attempts) { true }

      it "expires the pause and resets attempts" do
        pause_tracker.expects(:expire)
        pause_tracker.expects(:reset)
        command.expects(:result).with("applied")
        command.call
      end
    end
  end
end
