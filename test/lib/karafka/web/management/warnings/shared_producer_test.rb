# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new.call }
  let(:producer) { stub(idempotent?: false, transactional?: false) }

  before { Karafka.stubs(:producer).returns(producer) }

  context "when the default Karafka producer is neither idempotent nor transactional" do
    it "expect not to warn" do
      Karafka.logger.expects(:warn).never
      check
    end
  end

  context "when the default Karafka producer is idempotent" do
    before { producer.stubs(:idempotent?).returns(true) }

    it "expect to warn once about the shared producer" do
      Karafka.logger
        .expects(:warn)
        .with { |message| message.include?("Unable to reconstruct MessageSet") }
        .once

      check
    end

    it "expect to say that the Web UI reports and the application messages stop" do
      Karafka.logger
        .expects(:warn)
        .with { |message| message.include?("application messages, the Karafka Web UI reports") }

      check
    end

    it "expect to point to the custom Web UI producer docs" do
      Karafka.logger
        .expects(:warn)
        .with { |message| message.include?("#using-a-custom-web-ui-producer") }

      check
    end

    context "when a custom Web UI producer is configured" do
      before { Karafka::Web.config.stubs(:producer).returns(stub) }

      it "expect not to warn" do
        Karafka.logger.expects(:warn).never
        check
      end
    end
  end

  context "when the default Karafka producer is transactional" do
    before { producer.stubs(:transactional?).returns(true) }

    it "expect to warn once about the shared producer" do
      Karafka.logger
        .expects(:warn)
        .with { |message| message.include?("Unable to reconstruct MessageSet") }
        .once

      check
    end

    context "when a custom Web UI producer is configured" do
      before { Karafka::Web.config.stubs(:producer).returns(stub) }

      it "expect not to warn" do
        Karafka.logger.expects(:warn).never
        check
      end
    end
  end
end
