# frozen_string_literal: true

RSpec.describe_current do
  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL class methods" do
    let(:test_class) do
      Class.new(described_class) do
        depends_on :some_check
        independent!
      end
    end

    describe ".depends_on" do
      it "sets the dependency" do
        expect(test_class.dependency).to eq(:some_check)
      end
    end

    describe ".dependency" do
      context "when no dependency is set" do
        let(:no_dep_class) { Class.new(described_class) }

        it "returns nil" do
          expect(no_dep_class.dependency).to be_nil
        end
      end
    end

    describe ".independent!" do
      it "marks the class as independent" do
        expect(test_class.independent?).to be(true)
      end
    end

    describe ".independent?" do
      context "when not marked as independent" do
        let(:dependent_class) { Class.new(described_class) }

        it "returns false" do
          expect(dependent_class.independent?).to be(false)
        end
      end
    end

    describe ".halted_details" do
      it "returns empty hash by default" do
        expect(described_class.halted_details).to eq({})
      end

      context "when overridden in subclass" do
        let(:custom_class) do
          Class.new(described_class) do
            def self.halted_details
              { custom: :details }
            end
          end
        end

        it "returns the custom details" do
          expect(custom_class.halted_details).to eq({ custom: :details })
        end
      end
    end
  end

  describe "#initialize" do
    subject(:check) { described_class.new(context) }

    it "stores the context" do
      expect(check.send(:context)).to eq(context)
    end
  end

  describe "#call" do
    subject(:check) { described_class.new(context) }

    it "raises NotImplementedError" do
      expect { check.call }.to raise_error(NotImplementedError, "Subclasses must implement #call")
    end
  end

  describe "#step" do
    subject(:check) { described_class.new(context) }

    it "creates a Step with the given status and details" do
      result = check.send(:step, :success, { key: "value" })

      expect(result).to be_a(Karafka::Web::Ui::Models::Status::Step)
      expect(result.status).to eq(:success)
      expect(result.details).to eq({ key: "value" })
    end

    it "creates a Step with empty hash details when not provided" do
      result = check.send(:step, :failure)

      expect(result.status).to eq(:failure)
      expect(result.details).to eq({})
    end
  end
end
