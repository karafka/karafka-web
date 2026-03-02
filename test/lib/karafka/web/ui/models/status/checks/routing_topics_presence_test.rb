# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { assert_equal(false, described_class.independent?) }
    it { assert_equal(:consumers_reports_schema_state, described_class.dependency) }
    it { assert_equal([], described_class.halted_details) }
  end

  describe "#call" do
    let(:existing_topics) { %w[topic1 topic2 topic3] }

    before do
      context.cluster_info = Struct.new(:topics).new(
        existing_topics.map { |name| { topic_name: name } }
      )
    end

    context "when all routed topics exist in cluster" do
      let(:topic) do
        instance_double(Karafka::Routing::Topic, name: "topic1", active?: true).tap do |t|
          allow(t).to receive(:respond_to?).with(:patterns?).and_return(false)
        end
      end

      let(:topics_collection) do
        instance_double(Karafka::Routing::Topics).tap do |tc|
          allow(tc).to receive(:map).and_yield(topic).and_return([topic])
        end
      end

      let(:consumer_group) do
        instance_double(Karafka::Routing::ConsumerGroup, topics: topics_collection)
      end

      before do
        allow(Karafka::App).to receive(:routes).and_return([consumer_group])
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert_empty(result.details)
      end
    end

    context "when some routed topics are missing from cluster" do
      let(:missing_topic) do
        instance_double(Karafka::Routing::Topic, name: "missing_topic", active?: true).tap do |t|
          allow(t).to receive(:respond_to?).with(:patterns?).and_return(false)
        end
      end

      let(:topics_collection) do
        instance_double(Karafka::Routing::Topics).tap do |tc|
          allow(tc).to receive(:map).and_yield(missing_topic).and_return([missing_topic])
        end
      end

      let(:consumer_group) do
        instance_double(Karafka::Routing::ConsumerGroup, topics: topics_collection)
      end

      before do
        allow(Karafka::App).to receive(:routes).and_return([consumer_group])
      end

      it "returns warning" do
        result = check.call

        assert_equal(:warning, result.status)
        assert_equal(true, result.success?)
      end

      it "includes missing topics in details" do
        result = check.call

        assert_includes(result.details, "missing_topic")
      end
    end

    context "when topic is a pattern topic" do
      # patterns? is a Pro-only method not available in OSS Karafka::Routing::Topic,
      # so we create a Struct-based test object that responds to the required methods
      let(:pattern_topic_class) do
        Struct.new(:name, :active?, :patterns?, keyword_init: true) do
          def respond_to?(method, *)
            return true if method == :patterns?

            super
          end
        end
      end

      let(:pattern_topic) do
        pattern_topic_class.new(name: "pattern_topic", active?: true, patterns?: true)
      end

      let(:topics_collection) do
        instance_double(Karafka::Routing::Topics).tap do |tc|
          allow(tc).to receive(:map).and_yield(pattern_topic).and_return([pattern_topic])
        end
      end

      let(:consumer_group) do
        instance_double(Karafka::Routing::ConsumerGroup, topics: topics_collection)
      end

      before do
        allow(Karafka::App).to receive(:routes).and_return([consumer_group])
      end

      it "ignores pattern topics and returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert_empty(result.details)
      end
    end

    context "when topic is inactive" do
      let(:inactive_topic) do
        instance_double(Karafka::Routing::Topic, name: "inactive_topic", active?: false).tap do |t|
          allow(t).to receive(:respond_to?).with(:patterns?).and_return(false)
        end
      end

      let(:topics_collection) do
        instance_double(Karafka::Routing::Topics).tap do |tc|
          allow(tc).to receive(:map).and_yield(inactive_topic).and_return([inactive_topic])
        end
      end

      let(:consumer_group) do
        instance_double(Karafka::Routing::ConsumerGroup, topics: topics_collection)
      end

      before do
        allow(Karafka::App).to receive(:routes).and_return([consumer_group])
      end

      it "ignores inactive topics and returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert_empty(result.details)
      end
    end
  end
end
