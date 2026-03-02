# frozen_string_literal: true

describe_current do
  let(:topic) { described_class.new(topic_data) }

  describe "#partitions" do
    context "when no partition data" do
      let(:topic_data) { { partitions: {} } }

      it { assert_empty(topic.partitions) }
    end

    context "when there is partition data" do
      let(:topic_data) do
        {
          partitions: {
            "0": {
              lag_stored: 0,
              lag_stored_d: 2
            }
          }
        }
      end

      it { assert_kind_of(Karafka::Web::Ui::Models::Partition, topic.partitions.first) }
    end
  end
end
