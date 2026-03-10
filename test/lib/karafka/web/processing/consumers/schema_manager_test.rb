# frozen_string_literal: true

describe_current do
  let(:manager) { described_class.new }

  let(:msg) do
    Struct.new(:payload).new(
      { schema_version: schema_version }
    )
  end

  describe "#initialize" do
    it "initializes as compatible" do
      assert_equal("compatible", manager.to_s)
    end
  end

  describe "#call" do
    context "when manager is in compatible state" do
      context "when it is the same version as in the process" do
        let(:schema_version) { Karafka::Web::Tracking::Consumers::Sampler::SCHEMA_VERSION }

        it "returns :current" do
          assert_equal(:current, manager.call(msg))
        end

        it "remains compatible after processing" do
          manager.call(msg)

          assert_equal("compatible", manager.to_s)
        end
      end

      context "when it is an older version" do
        let(:schema_version) { "1.1.0" }

        it "returns :older" do
          assert_equal(:older, manager.call(msg))
        end

        it "remains compatible after processing" do
          manager.call(msg)

          assert_equal("compatible", manager.to_s)
        end
      end

      context "when it is a newer version" do
        let(:schema_version) { "111.1.0" }

        it "returns :newer" do
          assert_equal(:newer, manager.call(msg))
        end

        it "remains compatible after processing" do
          manager.call(msg)

          assert_equal("compatible", manager.to_s)
        end
      end

      context "when schema version is nil" do
        let(:schema_version) { nil }

        it "returns :older when comparing nil version" do
          assert_equal(:older, manager.call(msg))
        end
      end

      context "when schema version is empty string" do
        let(:schema_version) { "" }

        it "returns :older when comparing empty version" do
          assert_equal(:older, manager.call(msg))
        end
      end

      context "when schema version has pre-release suffix" do
        let(:schema_version) { "2.0.0-alpha" }

        it "handles pre-release versions correctly" do
          assert_equal(:newer, manager.call(msg))
        end
      end
    end

    context "when manager is in incompatible state" do
      before { manager.invalidate! }

      let(:schema_version) { Karafka::Web::Tracking::Consumers::Sampler::SCHEMA_VERSION }

      it "still returns version comparison result" do
        result = manager.call(msg)

        assert_equal(:current, result)
      end

      it "remains incompatible after processing" do
        manager.call(msg)

        assert_equal("incompatible", manager.to_s)
      end
    end

    context "with malformed version strings" do
      let(:schema_version) { "not-a-version" }

      it "raises error for malformed versions" do
        assert_raises(ArgumentError) { manager.call(msg) }
      end
    end
  end

  describe "#invalidate!" do
    it "changes state to incompatible" do
      assert_equal("compatible", manager.to_s)
      manager.invalidate!

      assert_equal("incompatible", manager.to_s)
    end

    it "is idempotent" do
      manager.invalidate!
      manager.invalidate!

      assert_equal("incompatible", manager.to_s)
    end
  end

  describe "state management" do
    it "starts as compatible" do
      assert_equal("compatible", manager.to_s)
    end

    it "becomes incompatible after invalidation" do
      manager.invalidate!

      assert_equal("incompatible", manager.to_s)
    end
  end

  describe "#to_s" do
    it "returns compatible string representation" do
      assert_equal("compatible", manager.to_s)
    end

    context "when after invalidation" do
      before { manager.invalidate! }

      it "returns incompatible string representation" do
        assert_equal("incompatible", manager.to_s)
      end
    end
  end

  describe "version comparison behavior" do
    let(:current_version) { Karafka::Web::Tracking::Consumers::Sampler::SCHEMA_VERSION }

    context "with semantic versioning" do
      it "correctly identifies older major versions" do
        major_parts = current_version.split(".")
        older_major = "#{major_parts[0].to_i - 1}.#{major_parts[1]}.#{major_parts[2]}"

        message = Struct.new(:payload).new({ schema_version: older_major })

        assert_equal(:older, manager.call(message))
      end

      it "correctly identifies newer major versions" do
        major_parts = current_version.split(".")
        newer_major = "#{major_parts[0].to_i + 1}.#{major_parts[1]}.#{major_parts[2]}"

        message = Struct.new(:payload).new({ schema_version: newer_major })

        assert_equal(:newer, manager.call(message))
      end

      it "correctly identifies older minor versions" do
        parts = current_version.split(".")
        older_minor = "#{parts[0]}.#{parts[1].to_i - 1}.#{parts[2]}"

        message = Struct.new(:payload).new({ schema_version: older_minor })

        assert_equal(:older, manager.call(message))
      end

      it "correctly identifies newer minor versions" do
        parts = current_version.split(".")
        newer_minor = "#{parts[0]}.#{parts[1].to_i + 1}.#{parts[2]}"

        message = Struct.new(:payload).new({ schema_version: newer_minor })

        assert_equal(:newer, manager.call(message))
      end

      it "correctly identifies older patch versions" do
        parts = current_version.split(".")
        # Use a known older patch version, handling the case where patch is 0
        patch_version = parts[2].to_i
        older_patch = if patch_version > 0
          "#{parts[0]}.#{parts[1]}.#{patch_version - 1}"
        else
          # If patch is 0, use previous minor version with high patch
          "#{parts[0]}.#{parts[1].to_i - 1}.9"
        end

        message = Struct.new(:payload).new({ schema_version: older_patch })

        assert_equal(:older, manager.call(message))
      end

      it "correctly identifies newer patch versions" do
        parts = current_version.split(".")
        newer_patch = "#{parts[0]}.#{parts[1]}.#{parts[2].to_i + 1}"

        message = Struct.new(:payload).new({ schema_version: newer_patch })

        assert_equal(:newer, manager.call(message))
      end
    end

    context "with edge case versions" do
      it "handles version 0.0.0" do
        message = Struct.new(:payload).new({ schema_version: "0.0.0" })

        assert_equal(:older, manager.call(message))
      end

      it "handles very high version numbers" do
        message = Struct.new(:payload).new({ schema_version: "999.999.999" })

        assert_equal(:newer, manager.call(message))
      end

      it "handles single digit versions" do
        message = Struct.new(:payload).new({ schema_version: "1" })
        result = manager.call(message)

        refute_empty(%i[older newer current] & [result])
      end

      it "handles two-part versions" do
        message = Struct.new(:payload).new({ schema_version: "1.0" })
        result = manager.call(message)

        refute_empty(%i[older newer current] & [result])
      end
    end
  end

  describe "state consistency" do
    it "maintains consistent state across multiple calls" do
      current_version_message = Struct.new(:payload).new(
        { schema_version: Karafka::Web::Tracking::Consumers::Sampler::SCHEMA_VERSION }
      )

      5.times do
        assert_equal(:current, manager.call(current_version_message))
        assert_equal("compatible", manager.to_s)
      end
    end

    it "maintains incompatible state after invalidation across calls" do
      manager.invalidate!
      current_version_message = Struct.new(:payload).new(
        { schema_version: Karafka::Web::Tracking::Consumers::Sampler::SCHEMA_VERSION }
      )

      5.times do
        assert_equal(:current, manager.call(current_version_message))
        assert_equal("incompatible", manager.to_s)
      end
    end
  end
end
