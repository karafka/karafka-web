# frozen_string_literal: true

describe_current do
  let(:migrate) { described_class.new.call }

  let(:migrator) { Karafka::Web::Management::Migrator.new }

  before do
    migrator.class.stubs(:new).returns(migrator)
    migrator.stubs(:call)
  end

  it "expect to run the migrator" do
    migrator.expects(:call)
    migrate
  end
end
