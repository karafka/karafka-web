# frozen_string_literal: true

RSpec.describe_current do
  subject(:delete) { described_class.new.call }

  let(:topics) do
    -> { Karafka::Web::Ui::Models::ClusterInfo.topics(cached: false).map(&:topic_name) }
  end

  let(:consumers_states_topic) { generate_topic_name }
  let(:consumers_metrics_topic) { generate_topic_name }
  let(:consumers_reports_topic) { generate_topic_name }
  let(:consumers_commands_topic) { generate_topic_name }
  let(:errors_topic) { generate_topic_name }

  before do
    Karafka::Web.config.topics.consumers.states = consumers_states_topic
    Karafka::Web.config.topics.consumers.metrics = consumers_metrics_topic
    Karafka::Web.config.topics.consumers.reports = consumers_reports_topic
    Karafka::Web.config.topics.consumers.commands = consumers_commands_topic
    Karafka::Web.config.topics.errors = errors_topic
  end

  context 'when topics do not exist' do
    it { expect { delete }.not_to(change { topics.call.count }) }
  end

  context 'when consumers states topic exists' do
    let(:consumers_states_topic) { create_topic }

    it 'expect to remove it' do
      expect { delete }
        .to change { topics.call.include?(consumers_states_topic) }.from(true).to(false)
    end
  end

  context 'when consumers metrics topic exists' do
    let(:consumers_metrics_topic) { create_topic }

    it 'expect to remove it' do
      expect { delete }
        .to change { topics.call.include?(consumers_metrics_topic) }.from(true).to(false)
    end
  end

  context 'when consumers reports topic exists' do
    let(:consumers_reports_topic) { create_topic }

    it 'expect to remove it' do
      expect { delete }
        .to change { topics.call.include?(consumers_reports_topic) }.from(true).to(false)
    end
  end

  context 'when errors topic exists' do
    let(:errors_topic) { create_topic }

    it 'expect to remove it' do
      expect { delete }
        .to change { topics.call.include?(errors_topic) }.from(true).to(false)
    end
  end
end
