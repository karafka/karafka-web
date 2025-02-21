# frozen_string_literal: true

RSpec.describe_current do
  subject(:info) { described_class }

  let(:topic) { create_topic }
  let(:not_found_error) { Karafka::Web::Errors::Ui::NotFoundError }
  let(:non_existing_topic) { generate_topic_name }

  before { topic }

  it { expect { info.fetch }.not_to raise_error }
  it { expect(info.topics.map(&:topic_name)).to include(topic) }
  it { expect(info.topics.map(&:topic_name)).not_to include(non_existing_topic) }
  it { expect { info.topic(non_existing_topic) }.to raise_error(not_found_error) }
  it { expect(info.topic(topic)).not_to be_nil }
  it { expect(info.partitions_count(topic)).to eq(1) }
end
