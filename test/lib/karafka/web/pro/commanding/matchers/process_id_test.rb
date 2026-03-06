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
  let(:matcher) { described_class.new(message) }

  let(:current_process_id) { "process-123" }
  let(:message) do
    instance_double(
      Karafka::Messages::Message,
      payload: { matchers: matchers }
    )
  end
  let(:matchers) { {} }

  before do
    allow(Karafka::Web.config.tracking.consumers.sampler)
      .to receive(:process_id)
      .and_return(current_process_id)
  end

  describe "#apply?" do
    context "when process_id is not specified in matchers" do
      let(:matchers) { {} }

      it { refute(matcher.apply?) }
    end

    context "when process_id is specified in matchers" do
      let(:matchers) { { process_id: current_process_id } }

      it { assert(matcher.apply?) }
    end
  end

  describe "#matches?" do
    context "when process_id matches current process ID" do
      let(:matchers) { { process_id: current_process_id } }

      it { assert(matcher.matches?) }
    end

    context "when process_id does not match current process ID" do
      let(:matchers) { { process_id: "other-process-456" } }

      it { refute(matcher.matches?) }
    end

    context "when process_id is empty string" do
      let(:matchers) { { process_id: "" } }

      it { refute(matcher.matches?) }
    end
  end
end
