# frozen_string_literal: true

RSpec.describe_current do
  subject(:migrate) { described_class.new.call }

  let(:migrator) { Karafka::Web::Management::Migrator.new }

  before do
    allow(migrator.class).to receive(:new).and_return(migrator)
    allow(migrator).to receive(:call)
  end

  it 'expect to run the migrator' do
    migrate
    expect(migrator).to have_received(:call)
  end
end
