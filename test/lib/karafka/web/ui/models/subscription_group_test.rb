# frozen_string_literal: true

describe_current do
  let(:sg) { described_class.new(sg_data) }

  describe "#topics" do
    context "when no topic data" do
      let(:sg_data) { { topics: {} } }

      it { assert_empty(sg.topics) }
    end

    context "when there is sg data" do
      let(:sg_data) do
        {
          topics: {
            xda: {}
          }
        }
      end

      it { assert_kind_of(Karafka::Web::Ui::Models::Topic, sg.topics.first) }
    end
  end
end
