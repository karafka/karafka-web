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
  let(:app) { Karafka::Web::Pro::Ui::App }

  let(:reports_topic) { create_topic }

  let(:partition_scope) do
    %w[
      consumer_groups
      example_app6_app
      subscription_groups
      c4ca4238a0b9_0
      topics
      default
      partitions
      0
    ]
  end

  context "when visiting a topic without a lens" do
    before { get "health/topics/example_app6_app/default" }

    it "expect to redirect to the overview lens" do
      assert_equal(302, response.status)
      assert_includes(response.headers["location"], "health/topics/example_app6_app/default/overview")
    end
  end

  describe "#overview" do
    before { get "health/topics/example_app6_app/default/overview" }

    it "expect to render the per-partition overview for that topic" do
      assert_ok
      assert_body(breadcrumbs)
      refute_body(pagination)
      # The single partition of the default topic, with its lag and stored offset
      assert_body("213731273")
      assert_body("327355")
      # The per-topic lens sub-tabs are present, including the per-topic cluster lags lens
      assert_body("health/topics/example_app6_app/default/lags")
      assert_body("health/topics/example_app6_app/default/offsets")
      assert_body("health/topics/example_app6_app/default/changes")
      assert_body("health/topics/example_app6_app/default/cluster_lags")
    end

    context "when sorted" do
      before { get "health/topics/example_app6_app/default/overview?sort=id+desc" }

      it { assert_ok }
    end

    it "expect a high-lag partition row to use the error border (lag wins over process status)" do
      # the default partition's lag (213_731_273) is well above the high-lag threshold
      assert_ok
      assert_body("status-row-error")
      refute_body("status-row-running")
    end

    context "when the topic does not exist" do
      before { get "health/topics/example_app6_app/no-such-topic/overview" }

      it { assert_equal(404, status) }
    end

    context "when the consumer group does not exist" do
      before { get "health/topics/no-such-group/default/overview" }

      it { assert_equal(404, status) }
    end
  end

  describe "#lags" do
    before { get "health/topics/example_app6_app/default/lags" }

    it do
      assert_ok
      assert_body(breadcrumbs)
      assert_body("213731273")
    end

    context "when sorted" do
      before { get "health/topics/example_app6_app/default/lags?sort=lag+desc" }

      it { assert_ok }
    end
  end

  describe "#offsets" do
    before { get "health/topics/example_app6_app/default/offsets" }

    it do
      assert_ok
      assert_body(breadcrumbs)
      assert_body("327355")
    end

    context "when sorted" do
      before { get "health/topics/example_app6_app/default/offsets?sort=committed_offset+desc" }

      it { assert_ok }
    end

    context "when the partition is at risk due to LSO" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        partition_data = report.dig(*partition_scope)
        partition_data["committed_offset"] = 1_000
        partition_data["ls_offset"] = 3_000
        partition_data["ls_offset_fd"] = 1_000_000_000

        produce(reports_topic, report.to_json)

        get "health/topics/example_app6_app/default/offsets"
      end

      it do
        assert_ok
        assert_body("at_risk")
        assert_body("badge-warning")
        refute_body("stopped")
      end
    end
  end

  describe "#changes" do
    before { get "health/topics/example_app6_app/default/changes" }

    it do
      assert_ok
      assert_body(breadcrumbs)
      assert_body("Pause state change")
    end

    context "when sorted" do
      before { get "health/topics/example_app6_app/default/changes?sort=poll_state_ch+desc" }

      it { assert_ok }
    end
  end

  describe "#cluster_lags" do
    context "when the topic has cluster lag data" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).returns(
          "example_app6_app" => {
            "default" => {
              0 => { lag: 4_200, offset: 10 }
            }
          }
        )

        get "health/topics/example_app6_app/default/cluster_lags"
      end

      it "expect to render the per-partition cluster lags for that topic" do
        assert_ok
        assert_body(breadcrumbs)
        assert_body("4200")
      end

      context "when sorted" do
        before do
          Karafka::Admin.stubs(:read_lags_with_offsets).returns(
            "example_app6_app" => {
              "default" => {
                0 => { lag: 4_200, offset: 10 }
              }
            }
          )

          get "health/topics/example_app6_app/default/cluster_lags?sort=lag+desc"
        end

        it { assert_ok }
      end
    end

    context "when the topic is reported but has no cluster lag data" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).returns({})
        get "health/topics/example_app6_app/default/cluster_lags"
      end

      it "expect to render an empty table (not a 404) for a real reported topic" do
        assert_ok
        assert_body(breadcrumbs)
      end
    end

    context "when the topic exists nowhere (no cluster lags and not reported)" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).returns({})
        get "health/topics/example_app6_app/no-such-topic/cluster_lags"
      end

      it { assert_equal(404, status) }
    end
  end
end
