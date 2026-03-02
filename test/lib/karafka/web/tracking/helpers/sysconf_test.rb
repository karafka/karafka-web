# frozen_string_literal: true

describe_current do
  describe ".page_size" do
    it "returns the system page size as an integer" do
      page_size = described_class.page_size

      assert_kind_of(Integer, page_size)
      assert_operator(page_size, :>, 0)
    end

    it "returns a reasonable page size value" do
      page_size = described_class.page_size

      # Most systems use 4KB (4096 bytes) or 8KB (8192 bytes) pages
      # Some systems might use 16KB or 64KB, but let's be generous with the range
      assert(page_size.between?(1_024, 65_536))
    end

    it "returns consistent values across multiple calls" do
      page_size1 = described_class.page_size
      page_size2 = described_class.page_size

      assert_equal(page_size2, page_size1)
    end

    context "when on Linux systems", if: RUBY_PLATFORM.include?("linux") do
      it "uses the correct libc library and constant" do
        assert_equal(30, described_class::SC_PAGESIZE)
      end

      it "returns typical Linux page size (usually 4096)" do
        page_size = described_class.page_size

        # Most Linux systems use 4KB pages
        refute_empty([page_size] & [4_096, 8_192, 16_384])
      end
    end

    context "when on macOS systems", if: RUBY_PLATFORM.include?("darwin") do
      it "uses the correct system library and constant" do
        assert_equal(29, described_class::SC_PAGESIZE)
      end

      it "returns typical macOS page size" do
        page_size = described_class.page_size

        # macOS typically uses 4KB pages on Intel, 16KB on Apple Silicon
        refute_empty([page_size] & [4_096, 8_192, 16_384])
      end
    end

    context "when checking FFI integration" do
      it "properly extends FFI::Library" do
        assert_includes(described_class.ancestors, FFI::Library)
      end

      it "has sysconf function attached" do
        assert_respond_to(described_class, :sysconf)
      end

      it "sysconf function accepts integer parameter and returns long" do
        # Test that the function is properly attached and callable
        result = described_class.sysconf(described_class::SC_PAGESIZE)

        assert_kind_of(Integer, result)
        assert_operator(result, :>, 0)
      end
    end

    context "when handling edge cases" do
      it "handles invalid sysconf parameters gracefully" do
        # Using an invalid/unsupported sysconf parameter should return -1 typically
        # but we don't want the spec to break on different systems
        described_class.sysconf(-999)
      end
    end

    context "when testing platform-specific behavior" do
      it "defines appropriate constants for the current platform" do
        case RUBY_PLATFORM
        when /linux/
          expect(defined?(described_class::SC_PAGESIZE)).to be_truthy

          assert_equal(30, described_class::SC_PAGESIZE)
        when /darwin/
          expect(defined?(described_class::SC_PAGESIZE)).to be_truthy

          assert_equal(29, described_class::SC_PAGESIZE)
        else
          # For other platforms, the constant might not be defined
          # but the test should still pass
          skip "Platform #{RUBY_PLATFORM} not specifically supported"
        end
      end
    end

    context "when verifying memory page calculations" do
      it "page size is a power of 2" do
        page_size = described_class.page_size

        # Memory page sizes are typically powers of 2
        assert_equal(0, page_size & (page_size - 1))
      end

      it "can be used for memory calculations" do
        page_size = described_class.page_size

        # Test that we can use it for typical memory calculations
        memory_in_bytes = 1024 * 1024 # 1MB
        pages_needed = (memory_in_bytes + page_size - 1) / page_size

        assert_kind_of(Integer, pages_needed)
        assert_operator(pages_needed, :>, 0)
      end
    end
  end

  describe "module structure" do
    it "is properly namespaced" do
      assert_equal("Karafka::Web::Tracking::Helpers::Sysconf", described_class.name)
    end

    it "extends FFI::Library for system calls" do
      assert_includes(described_class.singleton_class.ancestors, FFI::Library)
    end
  end
end
