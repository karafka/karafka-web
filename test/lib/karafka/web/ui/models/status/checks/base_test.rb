# frozen_string_literal: true

describe_current do
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
        assert_equal(:some_check, test_class.dependency)
      end
    end

    describe ".dependency" do
      context "when no dependency is set" do
        let(:no_dep_class) { Class.new(described_class) }

        it "returns nil" do
          assert_nil(no_dep_class.dependency)
        end
      end
    end

    describe ".independent!" do
      it "marks the class as independent" do
        assert_predicate(test_class, :independent?)
      end
    end

    describe ".independent?" do
      context "when not marked as independent" do
        let(:dependent_class) { Class.new(described_class) }

        it "returns false" do
          refute_predicate(dependent_class, :independent?)
        end
      end
    end

    describe ".halted_details" do
      it "returns empty hash by default" do
        assert_equal({}, described_class.halted_details)
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
          assert_equal({ custom: :details }, custom_class.halted_details)
        end
      end
    end
  end

  describe "#initialize" do
    let(:check) { described_class.new(context) }

    it "stores the context" do
      assert_equal(context, check.send(:context))
    end
  end

  describe "#call" do
    let(:check) { described_class.new(context) }

    it "raises NotImplementedError" do
      expect { check.call }.to raise_error(NotImplementedError, "Subclasses must implement #call")
    end
  end

  describe "#step" do
    let(:check) { described_class.new(context) }

    it "creates a Step with the given status and details" do
      result = check.send(:step, :success, { key: "value" })

      assert_kind_of(Karafka::Web::Ui::Models::Status::Step, result)
      assert_equal(:success, result.status)
      assert_equal({ key: "value" }, result.details)
    end

    it "creates a Step with empty hash details when not provided" do
      result = check.send(:step, :failure)

      assert_equal(:failure, result.status)
      assert_equal({}, result.details)
    end
  end
end
