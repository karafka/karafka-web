# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }
  let(:current_state) { { dispatched_at: Time.now.to_f } }

  describe "DSL configuration" do
    it { assert_equal(false, described_class.independent?) }
    it { assert_equal(:materializing_lag, described_class.dependency) }
    it { assert_equal({}, described_class.halted_details) }
  end

  describe "#call" do
    before do
      context.current_state = current_state
    end

    context "when reports topic is subscribed" do
      let(:health_data) do
        {
          consumer_group1: {
            topics: {
              context.topics_consumers_reports => {},
              "other_topic" => {}
            }
          }
        }
      end

      before do
        allow(Karafka::Web::Ui::Models::Health)
          .to receive(:current)
          .with(current_state)
          .and_return(health_data)
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
      end

      it "caches subscriptions in context" do
        check.call

        assert_includes(context.subscriptions, context.topics_consumers_reports)
      end
    end

    context "when reports topic is not subscribed" do
      let(:health_data) do
        {
          consumer_group1: {
            topics: {
              "other_topic" => {}
            }
          }
        }
      end

      before do
        allow(Karafka::Web::Ui::Models::Health)
          .to receive(:current)
          .with(current_state)
          .and_return(health_data)
      end

      it "returns failure" do
        result = check.call

        assert_equal(:failure, result.status)
      end
    end

    context "when subscriptions are already cached" do
      before do
        context.subscriptions = [context.topics_consumers_reports]
        allow(Karafka::Web::Ui::Models::Health).to receive(:current)
      end

      it "does not fetch again" do
        check.call

        expect(Karafka::Web::Ui::Models::Health).not_to have_received(:current)
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
      end
    end
  end
end
