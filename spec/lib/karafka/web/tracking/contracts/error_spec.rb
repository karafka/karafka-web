# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:error) do
    {
      schema_version: "1.2.0",
      id: SecureRandom.uuid,
      type: "librdkafka.dispatch_error",
      error_class: "StandardError",
      error_message: "Raised",
      backtrace: "lib/file.rb",
      details: {},
      occurred_at: Time.now.to_f,
      process: {
        id: "my-process",
        tags: Karafka::Core::Taggable::Tags.new
      }
    }
  end

  it { expect(contract.call(error)).to be_success }

  context "when validating id" do
    context "when missing" do
      before { error.delete(:id) }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when not a string" do
      before { error[:id] = 123 }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when empty" do
      before { error[:id] = "" }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when valid uuid" do
      before { error[:id] = SecureRandom.uuid }

      it { expect(contract.call(error)).to be_success }
    end
  end

  context "when validating schema_version" do
    context "when missing" do
      before { error.delete(:schema_version) }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when not a string" do
      before { error[:schema_version] = 1 }

      it { expect(contract.call(error)).not_to be_success }
    end
  end

  context "when validating type" do
    context "when missing" do
      before { error.delete(:type) }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when not a string" do
      before { error[:type] = 1 }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when empty" do
      before { error[:type] = "" }

      it { expect(contract.call(error)).not_to be_success }
    end
  end

  context "when validating error_class" do
    context "when missing" do
      before { error.delete(:error_class) }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when not a string" do
      before { error[:error_class] = 1 }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when empty" do
      before { error[:error_class] = "" }

      it { expect(contract.call(error)).not_to be_success }
    end
  end

  context "when validating error_message" do
    context "when missing" do
      before { error.delete(:error_message) }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when not a string" do
      before { error[:error_message] = 1 }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when empty" do
      before { error[:error_message] = "" }

      it { expect(contract.call(error)).to be_success }
    end
  end

  context "when validating backtrace" do
    context "when missing" do
      before { error.delete(:backtrace) }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when not a string" do
      before { error[:backtrace] = 1 }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when empty" do
      before { error[:backtrace] = "" }

      it { expect(contract.call(error)).to be_success }
    end
  end

  context "when validating details" do
    context "when missing" do
      before { error.delete(:details) }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when not a string" do
      before { error[:details] = 1 }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when empty" do
      before { error[:details] = {} }

      it { expect(contract.call(error)).to be_success }
    end

    context "when not empty" do
      before { error[:details] = { rand => rand } }

      it { expect(contract.call(error)).to be_success }
    end
  end

  context "when validating occurred_at" do
    context "when missing" do
      before { error.delete(:occurred_at) }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when a string" do
      before { error[:occurred_at] = "1" }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when empty" do
      before { error[:occurred_at] = nil }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when numeric" do
      before { error[:occurred_at] = 1_685_459_118.65 }

      it { expect(contract.call(error)).to be_success }
    end
  end

  context "when validating process id" do
    context "when missing" do
      before { error[:process].delete(:id) }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when not a string" do
      before { error[:process][:id] = 1 }

      it { expect(contract.call(error)).not_to be_success }
    end

    context "when empty" do
      before { error[:process][:id] = "" }

      it { expect(contract.call(error)).not_to be_success }
    end
  end

  context "when validating process tags" do
    context "when missing" do
      before { error[:process].delete(:tags) }

      it { expect(contract.call(error)).to be_success }
    end

    context "when not a taggable" do
      before { error[:process][:tags] = 1 }

      it { expect(contract.call(error)).not_to be_success }
    end
  end
end
