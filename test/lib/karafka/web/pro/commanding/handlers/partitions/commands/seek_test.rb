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
      offset: desired_offset,
      prevent_overtaking: prevent_overtaking,
      force_resume: force_resume
    )
  end

  let(:coordinators) { stub }
  let(:coordinator) { stub }
  let(:pause_tracker) { stub }
  let(:topic) { "topic_name" }
  let(:partition_id) { 1 }
  let(:desired_offset) { 100 }
  let(:prevent_overtaking) { false }
  let(:force_resume) { false }
  let(:seek_message) { stub }

  before do
    listener.stubs(:coordinators).returns(coordinators)

    coordinators.stubs(:find_or_create).with(topic, partition_id).returns(coordinator)

    coordinator.stubs(:pause_tracker).returns(pause_tracker)
    coordinator.stubs(:seek_offset).returns(current_seek_offset)
    coordinator.stubs(:seek_offset=)

    pause_tracker.stubs(:reset).returns(true)
    pause_tracker.stubs(:expire).returns(true)

    command.stubs(:topic).returns(topic)
    command.stubs(:partition_id).returns(partition_id)
    command.stubs(:result).returns(nil)

    Karafka::Messages::Seek.stubs(:new).returns(seek_message)
    client.stubs(:mark_as_consumed!).returns(marking_success)
    client.stubs(:seek).returns(true)
  end

  describe "#call" do
    let(:current_seek_offset) { nil }
    let(:marking_success) { true }

    context "when prevent_overtaking is true" do
      let(:prevent_overtaking) { true }

      context "when current offset exists and is ahead" do
        let(:current_seek_offset) { desired_offset + 1 }

        it "prevents the seek operation" do
          command.expects(:result).with("prevented")
          client.expects(:mark_as_consumed!).never
          command.call
        end
      end

      context "when current offset exists but is behind" do
        let(:current_seek_offset) { desired_offset - 1 }

        it "executes seek operation" do
          client.expects(:mark_as_consumed!)
          command.expects(:result).with("applied")
          command.call
        end
      end
    end

    context "when marking as consumed fails" do
      let(:marking_success) { false }

      it "stops with lost partition result" do
        command.expects(:result).with("lost_partition")
        client.expects(:seek).never
        command.call
      end
    end

    context "when force_resume is true" do
      let(:force_resume) { true }

      it "expires the pause tracker" do
        pause_tracker.expects(:expire)
        command.call
      end
    end

    context "when force_resume is false" do
      let(:force_resume) { false }

      it "does not expire the pause tracker" do
        pause_tracker.expects(:expire).never
        command.call
      end
    end

    context "when all operations succeed" do
      it "executes the seek operation fully" do
        client.expects(:mark_as_consumed!)
        client.expects(:seek)
        coordinator.expects(:seek_offset=).with(desired_offset)
        pause_tracker.expects(:reset)
        command.expects(:result).with("applied")
        command.call
      end
    end
  end
end
