# frozen_string_literal: true

describe_current do
  let(:aggregated) { described_class.new(input) }

  # The drift/gap compensation only touches the :seconds range, so we drive the test through a
  # :days range with two samples: the second one gets the deltas and the derived batch_size.
  let(:input) do
    {
      seconds: [],
      days: [
        [1_000, sample(messages: 0, batches: 0)],
        [2_000, sample(messages: 1_000, batches: 47)]
      ]
    }
  end

  def sample(messages:, batches:)
    {
      jobs: 0, batches: batches, messages: messages,
      errors: 0, retries: 0, dead: 0, rss: 0, processes: 0
    }
  end

  # The enriched batch_size of the most recent (delta-bearing) day sample
  let(:batch_size) { aggregated[:days].last[1][:batch_size] }

  describe "#batch_size (average messages per batch)" do
    it "uses float division and rounds to 2 decimals instead of flooring" do
      # 1000 / 47 => 21.2765..., previously floored to 21
      assert_in_delta(21.28, batch_size, 0.001)
    end

    context "when the average is a whole number" do
      let(:input) do
        {
          seconds: [],
          days: [
            [1_000, sample(messages: 0, batches: 0)],
            [2_000, sample(messages: 100, batches: 25)]
          ]
        }
      end

      it "is returned as an exact value" do
        assert_in_delta(4.0, batch_size, 0.001)
      end
    end

    context "when there are no batches in the window" do
      let(:input) do
        {
          seconds: [],
          days: [
            [1_000, sample(messages: 0, batches: 0)],
            [2_000, sample(messages: 5, batches: 0)]
          ]
        }
      end

      it "is zero and does not divide by zero" do
        assert_equal(0, batch_size)
      end
    end
  end
end
