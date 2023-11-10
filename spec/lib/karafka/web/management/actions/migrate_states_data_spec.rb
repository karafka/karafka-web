# frozen_string_literal: true

RSpec.describe_current do
  subject(:migrate) { described_class.new.call }

  let(:migrator) { Karafka::Management::Migrator.new }

  before { allow(migrator.class).to receive(:new).and_return(migrator) }

  it 'expect to run the migrator' do
    migrate
    expect(migrator).to have_received(:call)
  end
end
