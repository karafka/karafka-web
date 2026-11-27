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
  let(:helper_class) do
    Class.new do
      include Karafka::Web::Ui::Helpers::TimeHelper
      include Karafka::Web::Pro::Ui::Helpers::TimeHelper

      # Mock the kafka_state_badge method since it's not defined in TimeHelper
      def kafka_state_badge(state)
        case state
        when "active"
          "badge-success"
        when "paused"
          "badge-warning"
        else
          "badge-secondary"
        end
      end
    end
  end

  let(:helper) { helper_class.new }

  describe "#time_with_label" do
    it "returns a span tag with millisecond timestamp title" do
      time = Time.new(2023, 1, 1, 12, 30, 45.123, "+00:00")
      expected_stamp = (time.to_f * 1_000).to_i

      result = helper.time_with_label(time)

      assert_equal(%(<span title="#{expected_stamp}">#{time}</span>), result)
    end

    it "converts time to milliseconds correctly" do
      time = Time.at(1_672_531_200.123)
      expected_ms = 1_672_531_200_123

      result = helper.time_with_label(time)

      assert_includes(result, "title=\"#{expected_ms}\"")
    end

    it "handles time objects with different precisions" do
      time = Time.at(1_672_531_200)
      expected_ms = 1_672_531_200_000

      result = helper.time_with_label(time)

      assert_includes(result, "title=\"#{expected_ms}\"")
    end
  end

  describe "#human_readable_time" do
    context "when seconds are less than 60" do
      it "returns seconds with appropriate decimal places" do
        assert_equal("0 seconds", helper.human_readable_time(0))
        assert_equal("30.5 seconds", helper.human_readable_time(30.5))
      end
    end

    context "when seconds are between 60 and 3599 (1 minute to 59 minutes)" do
      it "returns minutes with 2 decimal places" do
        assert_equal("1.0 minutes", helper.human_readable_time(60))
        assert_equal("1.5 minutes", helper.human_readable_time(90))
        assert_equal("30.0 minutes", helper.human_readable_time(1800))
        assert_equal("59.98 minutes", helper.human_readable_time(3599))
      end
    end

    context "when seconds are between 3600 and 86399 (1 hour to 23 hours)" do
      it "returns hours with 2 decimal places" do
        assert_equal("1.0 hours", helper.human_readable_time(3600))
        assert_equal("2.0 hours", helper.human_readable_time(7200))
        assert_equal("1.5 hours", helper.human_readable_time(5400))
        assert_equal("24.0 hours", helper.human_readable_time(86_399))
      end
    end

    context "when seconds are 86400 or more (1 day or more)" do
      it "returns days with 2 decimal places" do
        assert_equal("1.0 days", helper.human_readable_time(86_400))
        assert_equal("2.0 days", helper.human_readable_time(172_800))
        assert_equal("1.5 days", helper.human_readable_time(129_600))
        assert_equal("11.57 days", helper.human_readable_time(1_000_000))
      end
    end

    it "handles edge cases at boundaries" do
      # Test the actual behavior of the method at boundaries
      assert_equal("59 seconds", helper.human_readable_time(59))
      assert_equal("1.0 minutes", helper.human_readable_time(60))
      assert_equal("1.0 hours", helper.human_readable_time(3600))
      assert_equal("1.0 days", helper.human_readable_time(86_400))
    end
  end

  describe "#poll_state_with_change_time_label" do
    let(:year_in_seconds) { 131_556_926 }

    context "when state is active" do
      it "returns badge without title or time information" do
        result = helper.poll_state_with_change_time_label("active", 1_000)

        assert_equal(%(<span class="badge badge-success">active</span>), result.strip)
      end
    end

    context "when state is not active and state_ch is greater than a year" do
      it 'returns badge with "until manual resume" title' do
        state_ch = (year_in_seconds + 1_000) * 1_000 # Convert to milliseconds

        result = helper.poll_state_with_change_time_label("paused", state_ch)

        # Check for key components instead of exact match due to whitespace
        assert_includes(result, 'class="badge badge-warning"')
        assert_includes(result, 'title="until manual resume"')
        assert_includes(result, "paused")
      end
    end

    context "when state is not active and state_ch is less than a year" do
      it "returns badge with future time title" do
        state_ch = 5000 # 5 seconds in milliseconds
        current_time = Time.now

        Time.stubs(:now).returns(current_time)

        result = helper.poll_state_with_change_time_label("paused", state_ch)
        expected_time = current_time + (state_ch / 1_000.0)

        # Check for key components instead of exact match due to whitespace
        assert_includes(result, 'class="badge badge-warning time-title"')
        assert_includes(result, "title=\"#{expected_time}\"")
        assert_includes(result, "paused")
      end

      it "correctly calculates future time from current time" do
        state_ch = 10_000 # 10 seconds in milliseconds
        freeze_time = Time.new(2023, 1, 1, 12, 0, 0)

        Time.stubs(:now).returns(freeze_time)

        result = helper.poll_state_with_change_time_label("paused", state_ch)
        expected_time = freeze_time + 10

        assert_includes(result, "title=\"#{expected_time}\"")
      end
    end

    context "with different states" do
      it "works with different state values" do
        result = helper.poll_state_with_change_time_label("suspended", 1_000)

        assert_includes(result, 'class="badge badge-secondary time-title"')
        assert_includes(result, "suspended")
      end
    end

    context "when testing edge cases" do
      it "handles exactly one year threshold" do
        state_ch = (131_556_926 + 1) * 1_000 # Just over one year in milliseconds

        result = helper.poll_state_with_change_time_label("paused", state_ch)

        assert_includes(result, 'title="until manual resume"')
      end

      it "handles zero state_ch value" do
        Time.stubs(:now).returns(Time.new(2023, 1, 1))

        result = helper.poll_state_with_change_time_label("paused", 0)

        assert_includes(result, "time-title")
        assert_includes(result, "2023-01-01")
      end
    end
  end
end
