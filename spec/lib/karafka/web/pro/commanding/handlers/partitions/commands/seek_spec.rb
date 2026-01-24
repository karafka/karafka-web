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
  subject(:command) { described_class.new(listener, client, request) }

  let(:listener) { instance_double(Karafka::Connection::Listener) }
  let(:client) { instance_double(Karafka::Connection::Client) }
  let(:request) do
    Karafka::Web::Pro::Commanding::Request.new(
      offset: desired_offset,
      prevent_overtaking: prevent_overtaking,
      force_resume: force_resume
    )
  end

  let(:coordinators) { instance_double(Karafka::Processing::CoordinatorsBuffer) }
  let(:coordinator) { instance_double(Karafka::Processing::Coordinator) }
  let(:pause_tracker) { instance_double(Karafka::TimeTrackers::Pause) }
  let(:topic) { 'topic_name' }
  let(:partition_id) { 1 }
  let(:desired_offset) { 100 }
  let(:prevent_overtaking) { false }
  let(:force_resume) { false }
  let(:seek_message) { instance_double(Karafka::Messages::Seek) }

  before do
    allow(listener)
      .to receive(:coordinators)
      .and_return(coordinators)

    allow(coordinators)
      .to receive(:find_or_create)
      .with(topic, partition_id)
      .and_return(coordinator)

    allow(coordinator).to receive_messages(
      pause_tracker: pause_tracker,
      seek_offset: current_seek_offset,
      'seek_offset=': nil
    )

    allow(pause_tracker).to receive_messages(
      reset: true,
      expire: true
    )

    allow(command).to receive_messages(topic: topic, partition_id: partition_id, result: nil)

    allow(Karafka::Messages::Seek).to receive(:new).and_return(seek_message)
    allow(client).to receive_messages(
      mark_as_consumed!: marking_success,
      seek: true
    )
  end

  describe '#call' do
    let(:current_seek_offset) { nil }
    let(:marking_success) { true }

    context 'when prevent_overtaking is true' do
      let(:prevent_overtaking) { true }

      context 'when current offset exists and is ahead' do
        let(:current_seek_offset) { desired_offset + 1 }

        it 'prevents the seek operation' do
          command.call
          expect(command).to have_received(:result).with('prevented')
          expect(client).not_to have_received(:mark_as_consumed!)
        end
      end

      context 'when current offset exists but is behind' do
        let(:current_seek_offset) { desired_offset - 1 }

        it 'executes seek operation' do
          command.call
          expect(client).to have_received(:mark_as_consumed!)
          expect(command).to have_received(:result).with('applied')
        end
      end
    end

    context 'when marking as consumed fails' do
      let(:marking_success) { false }

      it 'stops with lost partition result' do
        command.call
        expect(command).to have_received(:result).with('lost_partition')
        expect(client).not_to have_received(:seek)
      end
    end

    context 'when force_resume is true' do
      let(:force_resume) { true }

      it 'expires the pause tracker' do
        command.call
        expect(pause_tracker).to have_received(:expire)
      end
    end

    context 'when force_resume is false' do
      let(:force_resume) { false }

      it 'does not expire the pause tracker' do
        command.call
        expect(pause_tracker).not_to have_received(:expire)
      end
    end

    context 'when all operations succeed' do
      it 'executes the seek operation fully' do
        command.call

        expect(client).to have_received(:mark_as_consumed!)
        expect(client).to have_received(:seek)
        expect(coordinator).to have_received(:seek_offset=).with(desired_offset)
        expect(pause_tracker).to have_received(:reset)
        expect(command).to have_received(:result).with('applied')
      end
    end
  end
end
