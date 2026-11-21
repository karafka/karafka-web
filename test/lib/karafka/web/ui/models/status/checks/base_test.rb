# frozen_string_literal: true

describe_current do
  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL class methods" do
    let(:check_class) do
      Class.new(described_class) do
        depends_on :some_check
        independent!
      end
    end

    describe ".depends_on" do
      it "sets the dependency" do
        assert_equal(:some_check, check_class.dependency)
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
        assert(check_class.independent?)
      end
    end

    describe ".independent?" do
      context "when not marked as independent" do
        let(:dependent_class) { Class.new(described_class) }

        it "returns false" do
          refute(dependent_class.independent?)
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
    let(:check_class) do
      Class.new(described_class) do
        def call
          step(:success, { context: context })
        end
      end
    end

    let(:check) { check_class.new(context) }

    it "stores the context" do
      assert_same(context, check.call.details[:context])
    end
  end

  describe "#call" do
    let(:check) { described_class.new(context) }

    it "raises NotImplementedError" do
      e = assert_raises(NotImplementedError) { check.call }
      assert_includes(e.message, "Subclasses must implement #call")
    end
  end

  describe "#step" do
    let(:success_class) do
      Class.new(described_class) do
        def call
          step(:success, { key: "value" })
        end
      end
    end

    let(:failure_class) do
      Class.new(described_class) do
        def call
          step(:failure)
        end
      end
    end

    it "creates a Step with the given status and details" do
      result = success_class.new(context).call

      assert_kind_of(Karafka::Web::Ui::Models::Status::Step, result)
      assert_equal(:success, result.status)
      assert_equal({ key: "value" }, result.details)
    end

    it "creates a Step with empty hash details when not provided" do
      result = failure_class.new(context).call

      assert_equal(:failure, result.status)
      assert_equal({}, result.details)
    end
  end
end
