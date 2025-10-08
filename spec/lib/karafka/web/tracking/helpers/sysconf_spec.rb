# frozen_string_literal: true

RSpec.describe_current do
  describe '.page_size' do
    it 'returns the system page size as an integer' do
      page_size = described_class.page_size

      expect(page_size).to be_a(Integer)
      expect(page_size).to be > 0
    end

    it 'returns a reasonable page size value' do
      page_size = described_class.page_size

      # Most systems use 4KB (4096 bytes) or 8KB (8192 bytes) pages
      # Some systems might use 16KB or 64KB, but let's be generous with the range
      expect(page_size).to be_between(1_024, 65_536)
    end

    it 'returns consistent values across multiple calls' do
      page_size1 = described_class.page_size
      page_size2 = described_class.page_size

      expect(page_size1).to eq(page_size2)
    end

    context 'when on Linux systems', if: RUBY_PLATFORM.include?('linux') do
      it 'uses the correct libc library and constant' do
        expect(described_class::SC_PAGESIZE).to eq(30)
      end

      it 'returns typical Linux page size (usually 4096)' do
        page_size = described_class.page_size

        # Most Linux systems use 4KB pages
        expect([page_size] & [4_096, 8_192, 16_384]).not_to be_empty
      end
    end

    context 'when on macOS systems', if: RUBY_PLATFORM.include?('darwin') do
      it 'uses the correct system library and constant' do
        expect(described_class::SC_PAGESIZE).to eq(29)
      end

      it 'returns typical macOS page size' do
        page_size = described_class.page_size

        # macOS typically uses 4KB pages on Intel, 16KB on Apple Silicon
        expect([page_size] & [4_096, 8_192, 16_384]).not_to be_empty
      end
    end

    context 'when checking FFI integration' do
      it 'properly extends FFI::Library' do
        expect(described_class.ancestors).to include(FFI::Library)
      end

      it 'has sysconf function attached' do
        expect(described_class).to respond_to(:sysconf)
      end

      it 'sysconf function accepts integer parameter and returns long' do
        # Test that the function is properly attached and callable
        result = described_class.sysconf(described_class::SC_PAGESIZE)
        expect(result).to be_a(Integer)
        expect(result).to be > 0
      end
    end

    context 'when handling edge cases' do
      it 'handles invalid sysconf parameters gracefully' do
        # Using an invalid/unsupported sysconf parameter should return -1 typically
        # but we don't want the spec to break on different systems
        expect { described_class.sysconf(-999) }.not_to raise_error
      end
    end

    context 'when testing platform-specific behavior' do
      it 'defines appropriate constants for the current platform' do
        case RUBY_PLATFORM
        when /linux/
          expect(defined?(described_class::SC_PAGESIZE)).to be_truthy
          expect(described_class::SC_PAGESIZE).to eq(30)
        when /darwin/
          expect(defined?(described_class::SC_PAGESIZE)).to be_truthy
          expect(described_class::SC_PAGESIZE).to eq(29)
        else
          # For other platforms, the constant might not be defined
          # but the test should still pass
          skip "Platform #{RUBY_PLATFORM} not specifically supported"
        end
      end
    end

    context 'when verifying memory page calculations' do
      it 'page size is a power of 2' do
        page_size = described_class.page_size

        # Memory page sizes are typically powers of 2
        expect(page_size & (page_size - 1)).to eq(0)
      end

      it 'can be used for memory calculations' do
        page_size = described_class.page_size

        # Test that we can use it for typical memory calculations
        memory_in_bytes = 1024 * 1024 # 1MB
        pages_needed = (memory_in_bytes + page_size - 1) / page_size

        expect(pages_needed).to be_a(Integer)
        expect(pages_needed).to be > 0
      end
    end
  end

  describe 'module structure' do
    it 'is properly namespaced' do
      expect(described_class.name).to eq('Karafka::Web::Tracking::Helpers::Sysconf')
    end

    it 'extends FFI::Library for system calls' do
      expect(described_class.singleton_class.ancestors).to include(FFI::Library)
    end
  end
end
