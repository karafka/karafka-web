# frozen_string_literal: true

describe_current do
  let(:delete) { described_class.new.call }

  let(:topics) do
    lambda do
      Karafka::Web.config.ui.cache.clear
      Karafka::Web::Ui::Models::ClusterInfo.topics.map(&:topic_name)
    end
  end

  let(:consumers_states_topic) { generate_topic_name }
  let(:consumers_metrics_topic) { generate_topic_name }
  let(:consumers_reports_topic) { generate_topic_name }
  let(:consumers_commands_topic) { generate_topic_name }
  let(:errors_topic) { generate_topic_name }

  before do
    Karafka::Web.config.topics.consumers.states.name = consumers_states_topic
    Karafka::Web.config.topics.consumers.metrics.name = consumers_metrics_topic
    Karafka::Web.config.topics.consumers.reports.name = consumers_reports_topic
    Karafka::Web.config.topics.consumers.commands.name = consumers_commands_topic
    Karafka::Web.config.topics.errors.name = errors_topic
  end

  context "when topics do not exist" do
    it "does not create any of the configured topics" do
      configured_topics = [
        consumers_states_topic,
        consumers_metrics_topic,
        consumers_reports_topic,
        consumers_commands_topic,
        errors_topic
      ]

      delete

      existing_topics = topics.call

      assert(configured_topics.none? { |t| existing_topics.include?(t) })
    end
  end

  context "when consumers states topic exists" do
    let(:consumers_states_topic) { create_topic }

    it "expect to remove it" do
      before_val = topics.call.include?(consumers_states_topic)
      delete
      after_val = topics.call.include?(consumers_states_topic)
      assert_equal(true, before_val)
      assert_equal(false, after_val)
    end
  end

  context "when consumers metrics topic exists" do
    let(:consumers_metrics_topic) { create_topic }

    it "expect to remove it" do
      before_val = topics.call.include?(consumers_metrics_topic)
      delete
      after_val = topics.call.include?(consumers_metrics_topic)
      assert_equal(true, before_val)
      assert_equal(false, after_val)
    end
  end

  context "when consumers reports topic exists" do
    let(:consumers_reports_topic) { create_topic }

    it "expect to remove it" do
      before_val = topics.call.include?(consumers_reports_topic)
      delete
      after_val = topics.call.include?(consumers_reports_topic)
      assert_equal(true, before_val)
      assert_equal(false, after_val)
    end
  end

  context "when errors topic exists" do
    let(:errors_topic) { create_topic }

    it "expect to remove it" do
      before_val = topics.call.include?(errors_topic)
      delete
      after_val = topics.call.include?(errors_topic)
      assert_equal(true, before_val)
      assert_equal(false, after_val)
    end
  end
end
