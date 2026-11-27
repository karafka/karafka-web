# frozen_string_literal: true

describe_current do
  let(:contract) { described_class.new }

  ["a" * 249, "...", "a.b-c_D9", "__consumer_offsets"].each do |topic_name|
    context "when topic name is #{topic_name[0, 20]} (#{topic_name.size} chars)" do
      it { assert(contract.call({ topic_name: topic_name }).success?) }
    end
  end

  ["a" * 250, "a" * 513, ".", "..", "", "a b", "a/b", "a\nb", "ä", nil, 1].each do |topic_name|
    context "when topic name is #{topic_name.inspect[0, 20]}" do
      let(:result) { contract.call({ topic_name: topic_name }) }

      it do
        refute(result.success?)
        assert_equal("needs to be a valid Kafka topic name", result.errors[:topic_name])
      end
    end
  end
end
