# frozen_string_literal: true

RSpec.describe_current do
  subject(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }
  let(:current_state) { { dispatched_at: Time.now.to_f } }

  describe 'DSL configuration' do
    it { expect(described_class.independent?).to be(false) }
    it { expect(described_class.dependency).to eq(:materializing_lag) }
    it { expect(described_class.halted_details).to eq({}) }
  end

  describe '#call' do
    before do
      context.current_state = current_state
    end

    context 'when reports topic is subscribed' do
      let(:health_data) do
        {
          consumer_group1: {
            topics: {
              context.topics_consumers_reports => {},
              'other_topic' => {}
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

      it 'returns success' do
        result = check.call

        expect(result.status).to eq(:success)
      end

      it 'caches subscriptions in context' do
        check.call

        expect(context.subscriptions).to include(context.topics_consumers_reports)
      end
    end

    context 'when reports topic is not subscribed' do
      let(:health_data) do
        {
          consumer_group1: {
            topics: {
              'other_topic' => {}
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

      it 'returns failure' do
        result = check.call

        expect(result.status).to eq(:failure)
      end
    end

    context 'when subscriptions are already cached' do
      before do
        context.subscriptions = [context.topics_consumers_reports]
        allow(Karafka::Web::Ui::Models::Health).to receive(:current)
      end

      it 'does not fetch again' do
        check.call

        expect(Karafka::Web::Ui::Models::Health).not_to have_received(:current)
      end

      it 'returns success' do
        result = check.call

        expect(result.status).to eq(:success)
      end
    end
  end
end
