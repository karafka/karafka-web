# frozen_string_literal: true

describe_current do
  let(:info) { described_class }

  let(:topic) { create_topic }

  before { topic }

  it { assert_includes(info.fetch.topics.map { |details| details[:topic_name] }, topic) }
end
