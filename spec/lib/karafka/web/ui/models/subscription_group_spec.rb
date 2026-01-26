# frozen_string_literal: true

RSpec.describe_current do
  subject(:sg) { described_class.new(sg_data) }

  describe "#topics" do
    context "when no topic data" do
      let(:sg_data) { { topics: {} } }

      it { expect(sg.topics).to be_empty }
    end

    context "when there is sg data" do
      let(:sg_data) do
        {
          topics: {
            xda: {}
          }
        }
      end

      it { expect(sg.topics.first).to be_a(Karafka::Web::Ui::Models::Topic) }
    end
  end
end
