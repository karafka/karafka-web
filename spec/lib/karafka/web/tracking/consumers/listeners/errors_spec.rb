# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  let(:error) { StandardError.new(-'This is an error') }
  let(:event) do
    {
      type: 'error.occurred',
      error: error
    }
  end

  context 'when error message string is frozen' do
    it 'expect to process it without problems' do
      expect { listener.on_error_occurred(event) }.not_to raise_error
    end
  end
end
