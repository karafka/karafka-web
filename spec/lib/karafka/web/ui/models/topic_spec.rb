# frozen_string_literal: true

RSpec.describe_current do
  subject(:topic) { described_class.new(topic_data) }

  describe "#partitions" do
    context "when no partition data" do
      let(:topic_data) { { partitions: {} } }

      it { expect(topic.partitions).to be_empty }
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

      it { expect(topic.partitions.first).to be_a(Karafka::Web::Ui::Models::Partition) }
    end
  end
end
