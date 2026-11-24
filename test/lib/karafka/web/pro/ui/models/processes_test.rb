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
  let(:state) { Fixtures.consumers_states_json }
  let(:report) { Fixtures.consumers_reports_json }
  let(:reports_topic) { create_topic }

  before do
    Karafka::Web.config.topics.consumers.reports.name = reports_topic
    produce(reports_topic, report.to_json)
  end

  describe ".find" do
    let(:lookup) { described_class.find(state, process_id) }

    context "when process with given id does not exist in the state" do
      let(:process_id) { SecureRandom.uuid }

      it { assert_raises(Karafka::Web::Errors::Ui::NotFoundError) { lookup } }
    end

    context "when process exists" do
      let(:process_id) { "shinra:1:1" }

      it { assert_kind_of(Karafka::Web::Ui::Models::Process, lookup) }
    end
  end

  describe "#by_member_id" do
    let(:mapping) { described_class.by_member_id(state) }
    let(:subscription_groups) do
      report[:consumer_groups].values.flat_map { |cg| cg[:subscription_groups].values }
    end

    context "when the processes report member ids" do
      it "maps each of them to its process and subscription group" do
        assert_equal(
          %w[
            karafka-1c5e2b3a-7d4f-4e8a-b6c9-0f2a3d4e5b6c
            my-static-instance-8b1f6c2e-3f2d-4a8e-9c1b-2d7e5f4a9b10
          ],
          mapping.keys.sort
        )

        membership = mapping.fetch("karafka-1c5e2b3a-7d4f-4e8a-b6c9-0f2a3d4e5b6c")

        assert_equal("shinra:1:1", membership[:process].id)
        assert_equal("c4ca4238a0b9_0", membership[:subscription_group].id)
      end
    end

    context "when the consumers did not join their groups yet" do
      let(:report) do
        report = Fixtures.consumers_reports_json
        report[:consumer_groups].each_value do |cg|
          cg[:subscription_groups].each_value { |sg| sg[:member_id] = "" }
        end
        report
      end

      it { assert_empty(mapping) }
    end

    context "when the processes run a version that does not report member ids" do
      let(:report) do
        report = Fixtures.consumers_reports_json
        report[:consumer_groups].each_value do |cg|
          cg[:subscription_groups].each_value { |sg| sg.delete(:member_id) }
        end
        report
      end

      it { assert_empty(mapping) }
    end

    context "when there are no active processes" do
      before { state[:processes][:"shinra:1:1"][:offset] = 1_000 }

      it { assert_empty(mapping) }
    end
  end
end
