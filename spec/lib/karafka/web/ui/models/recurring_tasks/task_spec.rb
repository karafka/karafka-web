# frozen_string_literal: true

RSpec.describe_current do
  subject(:task) { described_class.new(attrs) }

  let(:attrs) { { enabled: true } }

  it { expect(task.class).to be < Karafka::Web::Ui::Lib::HashProxy }

  describe '#enabled?' do
    context 'when enabled' do
      it { expect(task.enabled?).to be(true) }
    end

    context 'when disabled' do
      let(:attrs) { { enabled: false } }

      it { expect(task.enabled?).to be(false) }
    end
  end
end
