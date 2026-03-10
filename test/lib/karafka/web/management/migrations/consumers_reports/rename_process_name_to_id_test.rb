# frozen_string_literal: true

describe_current do
  let(:migration) { described_class.new }

  describe ".applicable?" do
    context "when schema version is less than 1.3.0" do
      it "returns true for 1.2.9" do
        assert(described_class.applicable?("1.2.9"))
      end

      it "returns true for 1.2.0" do
        assert(described_class.applicable?("1.2.0"))
      end

      it "returns true for 1.0.0" do
        assert(described_class.applicable?("1.0.0"))
      end
    end

    context "when schema version is 1.3.0 or higher" do
      it "returns false for 1.3.0" do
        refute(described_class.applicable?("1.3.0"))
      end

      it "returns false for 1.4.0" do
        refute(described_class.applicable?("1.4.0"))
      end

      it "returns false for 1.5.0" do
        refute(described_class.applicable?("1.5.0"))
      end
    end
  end

  describe "#migrate" do
    context "when report has process[:name] but not process[:id]" do
      let(:report) do
        {
          schema_version: "1.2.9",
          process: {
            name: "test-process:1:1",
            status: "running",
            memory_usage: 12_345
          },
          dispatched_at: Time.now.to_f
        }
      end

      it "renames :name to :id" do
        migration.migrate(report)

        assert_equal("test-process:1:1", report[:process][:id])
      end

      it "removes :name field" do
        migration.migrate(report)

        refute(report[:process].key?(:name))
      end

      it "preserves other fields" do
        original_status = report[:process][:status]
        original_memory = report[:process][:memory_usage]

        migration.migrate(report)

        assert_equal(original_status, report[:process][:status])
        assert_equal(original_memory, report[:process][:memory_usage])
      end
    end

    context "when report already has process[:id]" do
      let(:report) do
        {
          schema_version: "1.3.0",
          process: {
            id: "modern-process:2:2",
            status: "running"
          },
          dispatched_at: Time.now.to_f
        }
      end

      it "does not modify the report" do
        original_report = Marshal.load(Marshal.dump(report))

        migration.migrate(report)

        assert_equal(original_report, report)
      end
    end

    context "when report has both process[:name] and process[:id]" do
      let(:report) do
        {
          schema_version: "1.2.9",
          process: {
            name: "old-process:1:1",
            id: "new-process:2:2",
            status: "running"
          },
          dispatched_at: Time.now.to_f
        }
      end

      it "does not modify the report when :id already exists" do
        original_id = report[:process][:id]

        migration.migrate(report)

        assert_equal(original_id, report[:process][:id])
      end

      it "keeps the existing :id value" do
        migration.migrate(report)

        assert_equal("new-process:2:2", report[:process][:id])
      end
    end
  end
end
