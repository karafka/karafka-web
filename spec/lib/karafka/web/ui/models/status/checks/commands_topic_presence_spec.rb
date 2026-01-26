# frozen_string_literal: true

RSpec.describe_current do
  subject(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { expect(described_class.independent?).to be(false) }
    it { expect(described_class.dependency).to eq(:topics) }
  end

  describe "#call" do
    context "when Karafka Pro is not enabled" do
      before { allow(Karafka).to receive(:pro?).and_return(false) }

      it "returns success regardless of topic presence" do
        result = check.call

        expect(result.status).to eq(:success)
        expect(result.success?).to be(true)
      end
    end

    context "when Karafka Pro is enabled" do
      before { allow(Karafka).to receive(:pro?).and_return(true) }

      context "when commands topic exists" do
        before do
          context.cluster_info = Struct.new(:topics).new(
            [
              {
                topic_name: context.topics_consumers_commands,
                partition_count: 1,
                partitions: [{ replica_count: 1 }]
              }
            ]
          )
        end

        it "returns success" do
          result = check.call

          expect(result.status).to eq(:success)
          expect(result.success?).to be(true)
        end

        it "includes topic details" do
          result = check.call

          expect(result.details[:topic_name]).to eq(context.topics_consumers_commands)
          expect(result.details[:present]).to be(true)
        end
      end

      context "when commands topic does not exist" do
        before do
          context.cluster_info = Struct.new(:topics).new([])
        end

        it "returns warning" do
          result = check.call

          expect(result.status).to eq(:warning)
          expect(result.success?).to be(true)
        end

        it "includes topic details" do
          result = check.call

          expect(result.details[:topic_name]).to eq(context.topics_consumers_commands)
          expect(result.details[:present]).to be(false)
        end
      end
    end
  end
end
