# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  describe '#on_error_occurred' do
    let(:error) { StandardError.new(-'This is an error') }

    context 'when type is none of the consumer related' do
      let(:event) do
        {
          type: 'librdkafka.error',
          error: error
        }
      end

      it { expect { listener.on_error_occurred(event) }.not_to raise_error }
    end
  end
end
