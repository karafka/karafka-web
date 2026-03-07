# frozen_string_literal: true

describe_current do
  let(:app) { Karafka::Web::Ui::App }

  let(:states_topic) { create_topic }
  let(:reports_topic) { create_topic }

  describe "jobs/ path redirect" do
    context "when visiting the jobs/ path without type indicator" do
      before { get "jobs" }

      it "expect to redirect to running jobs page" do
        assert_equal(302, response.status)
        assert_includes(response.headers["location"], "jobs/running")
      end
    end
  end

  describe "#running" do
    context "when needed topics are missing" do
      before do
        topics_config.consumers.states.name = generate_topic_name
        topics_config.consumers.metrics.name = generate_topic_name
        topics_config.consumers.reports.name = generate_topic_name
        topics_config.errors.name = generate_topic_name

        get "jobs/running"
      end

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when needed topics are present" do
      before { get "jobs/running" }

      it do
        assert(response.ok?)
        assert_body("2023-08-01T09:47:51")
        assert_body("ActiveJob::Consumer")
        assert_body(support_message)
        assert_body(breadcrumbs)
        refute_body(pagination)
      end
    end

    context "when we have only jobs different than running" do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        data = Fixtures.consumers_states_json(symbolize_names: false)
        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report["jobs"][0]["status"] = "pending"

        produce(reports_topic, report.to_json)
        produce(states_topic, data.to_json)

        get "jobs/running"
      end

      it do
        assert(response.ok?)
        assert_body("There are no running jobs at the moment")
        refute_body("ActiveJob::Consumer")
        assert_body(support_message)
        assert_body(breadcrumbs)
        refute_body(pagination)
      end
    end

    context "when we have a running job without first and last offsets" do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        data = Fixtures.consumers_states_json(symbolize_names: false)
        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report["jobs"] = [report["jobs"][0]]
        report["jobs"][0]["first_offset"] = -1
        report["jobs"][0]["last_offset"] = -1

        produce(reports_topic, report.to_json)
        produce(states_topic, data.to_json)

        get "jobs/running"
      end

      it do
        assert(response.ok?)
        assert_body(support_message)
        assert_body(breadcrumbs)
        assert_body("N/A")
        refute_body(pagination)
      end
    end

    context "when we have a running eofed job without first and last offsets" do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        data = Fixtures.consumers_states_json(symbolize_names: false)
        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report["jobs"] = [report["jobs"][0]]
        report["jobs"][0]["type"] = "eofed"
        report["jobs"][0]["first_offset"] = -1
        report["jobs"][0]["last_offset"] = -1

        produce(reports_topic, report.to_json)
        produce(states_topic, data.to_json)

        get "jobs/running"
      end

      it do
        assert(response.ok?)
        assert_body("eofed")
        assert_body(support_message)
        assert_body(breadcrumbs)
        assert_body("N/A")
        refute_body(pagination)
      end
    end

    context "when there are more jobs than fits on a single page" do
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

      context "when visiting first page" do
        before { get "jobs/running" }

        it do
          assert(response.ok?)
          assert_body("2023-08-01T09:47:51")
          assert_equal(25, body.scan("ActiveJob::Consumer").size)
          assert_body(support_message)
          assert_body(breadcrumbs)
          assert_body(pagination)
          assert_body("shinra:0:0")
          assert_body("shinra:1:1")
          assert_body("shinra:11:11")
          assert_body("shinra:12:12")
          assert_equal(50, body.scan("shinra:").size)
        end
      end

      context "when visiting page with data reported in a transactional fashion" do
        before do
          topics_config.consumers.states.name = states_topic
          topics_config.consumers.reports.name = reports_topic

          produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
          produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

          get "jobs/running"
        end

        it do
          assert(response.ok?)
          assert_body("2023-08-01T09:47:51")
          assert_equal(25, body.scan("ActiveJob::Consumer").size)
          assert_body(support_message)
          assert_body(breadcrumbs)
          assert_body(pagination)
          assert_body("shinra:0:0")
          assert_body("shinra:1:1")
          assert_body("shinra:11:11")
          assert_body("shinra:12:12")
          assert_equal(50, body.scan("shinra:").size)
        end
      end

      context "when visiting higher page" do
        before { get "jobs/running?page=2" }

        it do
          assert(response.ok?)
          assert_body(pagination)
          assert_body(support_message)
          assert_body("shinra:32:32")
          assert_body("shinra:34:34")
          assert_body("shinra:35:35")
          assert_body("shinra:35:35")
          assert_equal(50, body.scan("shinra:").size)
        end
      end

      context "when visiting page beyond available" do
        before { get "jobs/running?page=100" }

        it do
          assert(response.ok?)
          assert_body(pagination)
          assert_body(support_message)
          assert_equal(0, body.scan("shinra:").size)
          assert_body(no_meaningful_results)
        end
      end
    end
  end

  describe "#pending" do
    context "when needed topics are missing" do
      before do
        topics_config.consumers.states.name = generate_topic_name
        topics_config.consumers.metrics.name = generate_topic_name
        topics_config.consumers.reports.name = generate_topic_name
        topics_config.errors.name = generate_topic_name

        get "jobs/pending"
      end

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when needed topics are present with data" do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        data = Fixtures.consumers_states_json(symbolize_names: false)
        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report["jobs"][0]["status"] = "pending"

        produce(reports_topic, report.to_json)
        produce(states_topic, data.to_json)

        get "jobs/pending"
      end

      it do
        assert(response.ok?)
        assert_body("2023-08-01T09:47:51")
        assert_body("ActiveJob::Consumer")
        assert_body(support_message)
        assert_body(breadcrumbs)
        refute_body(pagination)
      end
    end

    context "when we have only jobs different than pending" do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        data = Fixtures.consumers_states_json(symbolize_names: false)
        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report["jobs"][0]["status"] = "running"

        produce(reports_topic, report.to_json)
        produce(states_topic, data.to_json)

        get "jobs/pending"
      end

      it do
        assert(response.ok?)
        assert_body("There are no pending jobs at the moment")
        refute_body("ActiveJob::Consumer")
        assert_body(support_message)
        assert_body(breadcrumbs)
        refute_body(pagination)
      end
    end

    context "when there are more jobs than fits on a single page" do
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
          report["jobs"].first["status"] = "pending"

          produce(reports_topic, report.to_json, key: id)
        end

        produce(states_topic, data.to_json)
      end

      context "when visiting first page" do
        before { get "jobs/pending" }

        it do
          assert(response.ok?)
          assert_body("2023-08-01T09:47:51")
          assert_equal(25, body.scan("ActiveJob::Consumer").size)
          assert_body(support_message)
          assert_body(breadcrumbs)
          assert_body(pagination)
          assert_body("shinra:0:0")
          assert_body("shinra:1:1")
          assert_body("shinra:11:11")
          assert_body("shinra:12:12")
          assert_equal(50, body.scan("shinra:").size)
        end
      end

      context "when visiting page with data reported in a transactional fashion" do
        before do
          topics_config.consumers.states.name = states_topic
          topics_config.consumers.reports.name = reports_topic

          produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
          produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

          get "jobs/pending"
        end

        it do
          assert(response.ok?)
          assert_body("2023-08-01T09:47:51")
          assert_equal(25, body.scan("ActiveJob::Consumer").size)
          assert_body(support_message)
          assert_body(breadcrumbs)
          assert_body(pagination)
          assert_body("shinra:0:0")
          assert_body("shinra:1:1")
          assert_body("shinra:11:11")
          assert_body("shinra:12:12")
          assert_equal(50, body.scan("shinra:").size)
        end
      end

      context "when visiting higher page" do
        before { get "jobs/pending?page=2" }

        it do
          assert(response.ok?)
          assert_body(pagination)
          assert_body(support_message)
          assert_body("shinra:32:32")
          assert_body("shinra:34:34")
          assert_body("shinra:35:35")
          assert_body("shinra:35:35")
          assert_equal(50, body.scan("shinra:").size)
        end
      end

      context "when visiting page beyond available" do
        before { get "jobs/pending?page=100" }

        it do
          assert(response.ok?)
          assert_body(pagination)
          assert_body(support_message)
          assert_equal(0, body.scan("shinra:").size)
          assert_body(no_meaningful_results)
        end
      end
    end
  end
end
