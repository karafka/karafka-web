# frozen_string_literal: true

describe_current do
  let(:info) { described_class }

  let(:topic) { create_topic }
  let(:not_found_error) { Karafka::Web::Errors::Ui::NotFoundError }
  let(:non_existing_topic) { generate_topic_name }

  before { topic }

  it { info.fetch }

  it { assert_includes(info.topics.map(&:topic_name), topic) }
  it { refute_includes(info.topics.map(&:topic_name), non_existing_topic) }
  it { assert_raises(not_found_error) { info.topic(non_existing_topic) } }
  it { refute_nil(info.topic(topic)) }
  it { assert_equal(1, info.partitions_count(topic)) }
end
