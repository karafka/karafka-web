# frozen_string_literal: true

describe_current do
  let(:action) { described_class.new }
  let(:migrate) { action.call }

  let(:migrator) { Karafka::Web::Management::Migrator.new }
  let(:missing_metrics) { Karafka::Web::Errors::Processing::MissingConsumersMetricsError }
  let(:missing_state) { Karafka::Web::Errors::Processing::MissingConsumersStateError }

  before do
    migrator.class.stubs(:new).returns(migrator)
    migrator.stubs(:call)
    action.stubs(:sleep)
  end

  it "expect to run the migrator" do
    migrator.expects(:call)
    migrate
  end

  context "when the states become visible after a few attempts" do
    before do
      migrator
        .expects(:call)
        .times(3)
        .raises(missing_metrics)
        .then.raises(missing_state)
        .then.returns(nil)
    end

    it "expect to retry until the migrator succeeds" do
      migrate
    end

    it "expect to wait between attempts" do
      action.expects(:sleep).with(1).twice
      migrate
    end
  end

  context "when the metrics record is still missing after all the attempts" do
    before { migrator.expects(:call).times(5).raises(missing_metrics) }

    it "expect to raise the missing metrics error" do
      assert_raises(missing_metrics) { migrate }
    end
  end

  context "when the migrator fails with an unrelated error" do
    let(:incompatible) { Karafka::Web::Errors::Management::IncompatibleSchemaError }

    before { migrator.expects(:call).once.raises(incompatible) }

    it "expect not to retry" do
      assert_raises(incompatible) { migrate }
    end
  end
end
