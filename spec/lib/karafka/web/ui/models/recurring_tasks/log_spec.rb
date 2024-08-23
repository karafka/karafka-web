# frozen_string_literal: true

RSpec.describe_current do
  subject(:log) { described_class }

  it { expect(log).to be < Karafka::Web::Ui::Lib::HashProxy }
end
