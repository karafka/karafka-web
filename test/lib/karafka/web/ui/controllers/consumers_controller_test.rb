# frozen_string_literal: true

describe_current do
  let(:app) { Karafka::Web::Ui::App }

  let(:no_processes) { "There Are No Karafka Consumer Processes" }
  let(:states_topic) { create_topic }
  let(:reports_topic) { create_topic }

  context "when the state data is missing" do
    before do
      topics_config.consumers.states.name = states_topic

      get "consumers"
    end

    it do
      refute(response.ok?)
      assert_equal(404, status)
    end
  end

  context "when there are no active consumers" do
    before do
      topics_config.consumers.reports.name = states_topic

      get "consumers"
    end

    it do
      assert_ok
      assert_body(breadcrumbs)
      refute_body(pagination)
      assert_body(no_processes)
    end
  end

  context "when there are active consumers" do
    before { get "consumers" }

    it do
      assert_ok
      refute_body(no_processes)
      refute_body(pagination)
      assert_body(breadcrumbs)
      assert_body("246 MB")
      assert_body("shinra:1:1")
      refute_body("/consumers/shinra:1:1/subscriptions")
      assert_body("2690818651.82293")
    end
  end

  # The default consumer process (shinra:1:1) is subscribed to the "default", "test2" and "visits"
  # topics and is tagged "#8cbff36". We use those to exercise filtering on each allowed attribute,
  # both when it matches and when it does not.
  describe "filtering" do
    {
      "id" => { matching: "shinra", non_matching: "no-such-process" },
      "subscribed_topics" => { matching: "visits", non_matching: "no-such-topic" },
      "tags" => { matching: "8cbff36", non_matching: "no-such-tag" }
    }.each do |field, values|
      context "when filtering by the #{field} field" do
        context "when the value matches" do
          before { get "consumers?filter[field]=#{field}&filter[value]=#{values.fetch(:matching)}" }

          it "keeps the matching process" do
            assert_ok
            assert_body("shinra:1:1")
            # The selected field stays selected in the field dropdown
            assert_body(%(value="#{field}" selected))
          end
        end

        context "when the value does not match" do
          before do
            get "consumers?filter[field]=#{field}&filter[value]=#{values.fetch(:non_matching)}"
          end

          it "filters the process out" do
            assert_ok
            refute_body("shinra:1:1")
            # The filtering box stays rendered (so the filter can be adjusted or reset) and we do
            # not fall back to the "no consumers at all" empty state, they are just filtered out
            assert_body('name="filter[value]"')
            refute_body(no_processes)
          end
        end
      end
    end

    context "when scoping to a field the value does not belong to" do
      # 'visits' is a subscribed topic, not part of the process id 'shinra:1:1', so scoping to the
      # id field must exclude it (proving the field scoping actually applies)
      before { get "consumers?filter[field]=id&filter[value]=visits" }

      it do
        assert_ok
        refute_body("shinra:1:1")
      end
    end

    context "when filtering with a plain keyword (no field selected)" do
      context "when it matches on any attribute" do
        before { get "consumers?filter=8cbff36" }

        it do
          assert_ok
          assert_body("shinra:1:1")
        end
      end

      context "when it does not match anything" do
        before { get "consumers?filter=nothing-matches-this-keyword" }

        it "filters everything out" do
          assert_ok
          refute_body("shinra:1:1")
          refute_body(no_processes)
        end
      end
    end

    context "when there are multiple processes" do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        states = Fixtures.consumers_states_json(symbolize_names: false)
        states["processes"] = {}
        base_report = Fixtures.consumers_reports_json(symbolize_names: false)

        %w[web-a:1:1 web-b:2:2].each_with_index do |id, index|
          states["processes"][id] = { "dispatched_at" => 2_690_818_669.526_218, "offset" => index }

          report = base_report.dup
          report["process"] = base_report["process"].merge("id" => id)

          produce(reports_topic, report.to_json, key: id)
        end

        produce(states_topic, states.to_json)
      end

      it "keeps only the process matching the filter" do
        get "consumers?filter[field]=id&filter[value]=web-a"

        assert_ok
        assert_body("web-a:1:1")
        refute_body("web-b:2:2")
      end
    end
  end

  context "when there is an active consumer but without any partitions assigned yet" do
    before do
      topics_config.consumers.states.name = states_topic
      topics_config.consumers.reports.name = reports_topic

      report = Fixtures.consumers_reports_json
      scope = report[:consumer_groups][:example_app6_app][:subscription_groups][:c4ca4238a0b9_0]
      scope[:topics].clear

      produce(states_topic, Fixtures.consumers_states_file)
      produce(reports_topic, report.to_json)

      get "consumers"
    end

    it do
      assert_ok
      refute_body("partitions: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9")
      refute_body(no_processes)
      refute_body(pagination)
      assert_body(breadcrumbs)
      assert_body("246 MB")
      assert_body("shinra:1:1")
      refute_body("/consumers/shinra:1:1/subscriptions")
      assert_body("2690818651.82293")
    end
  end

  context "when there are active consumers with many partitions assigned" do
    before do
      topics_config.consumers.states.name = states_topic
      topics_config.consumers.reports.name = reports_topic

      report = Fixtures.consumers_reports_json
      scope = report[:consumer_groups][:example_app6_app][:subscription_groups][:c4ca4238a0b9_0]
      base = scope[:topics][:default][:partitions]

      50.times { |i| base[i + 1] = base[:"0"].dup.merge(id: i + 1) }

      produce(states_topic, Fixtures.consumers_states_file)
      produce(reports_topic, report.to_json)

      get "consumers"
    end

    it do
      assert_ok
      assert_body("0-50")
      assert_body("default-[0-50] (51 partitions total)")
      assert_body(breadcrumbs)
      refute_body(no_processes)
      refute_body(pagination)
      assert_body("246 MB")
      assert_body("shinra:1:1")
      refute_body("/consumers/shinra:1:1/subscriptions")
      assert_body("2690818651.82293")
    end
  end

  context "when there are active consumers reported in a transactional fashion" do
    before do
      topics_config.consumers.states.name = states_topic
      topics_config.consumers.reports.name = reports_topic

      produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
      produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

      get "consumers"
    end

    it do
      assert_ok
      assert_body(breadcrumbs)
      refute_body(no_processes)
      refute_body(pagination)
      assert_body("246 MB")
      assert_body("shinra:1:1")
      refute_body("/consumers/shinra:1:1/subscriptions")
      assert_body("2690818651.82293")
    end
  end

  context "when there are more consumers that we fit in a single page" do
    before do
      topics_config.consumers.states.name = states_topic
      topics_config.consumers.reports.name = reports_topic

      data = Fixtures.consumers_states_json(symbolize_names: false)
      base_report = Fixtures.consumers_reports_json(symbolize_names: false)

      100.times do |i|
        id = "shinra:#{i}:#{i}"

        data["processes"][id] = {
          dispatched_at: 2_690_818_669.526_218,
          offset: i
        }

        report = base_report.dup
        report["process"]["id"] = id

        produce(reports_topic, report.to_json, key: id)
      end

      produce(states_topic, data.to_json)
    end

    context "when we visit first page" do
      before { get "consumers" }

      it do
        assert_ok
        assert_body(pagination)
        assert_body("shinra:0:0")
        assert_body("shinra:1:1")
        assert_body("shinra:11:11")
        assert_body("shinra:12:12")
        assert_equal(25, body.scan("shinra:").size)
      end
    end

    context "when we visit second page" do
      before { get "consumers?page=2" }

      it do
        assert_ok
        assert_body(pagination)
        assert_body("shinra:32:32")
        assert_body("shinra:34:34")
        assert_body("shinra:35:35")
        assert_body("shinra:35:35")
        assert_equal(25, body.scan("shinra:").size)
      end
    end

    context "when we go beyond available pages" do
      before { get "consumers?page=100" }

      it do
        assert_ok
        assert_body(pagination)
        assert_equal(0, body.scan("shinra:").size)
        assert_body(no_meaningful_results)
      end
    end
  end
end
