# frozen_string_literal: true

RSpec.describe Karafka::Web::Tracking::Consumers::Sampler::Cgroup do
  subject(:cgroup) { described_class }

  # Reset memoized version between tests
  before do
    # Remove the memoized instance variable from the module's eigenclass
    # Since class methods are defined in 'class << self', the @version is stored
    # on the module itself (not its singleton class)
    described_class.send(:remove_instance_variable, :@version) if described_class.instance_variable_defined?(:@version)
  end

  describe '.version' do
    context 'when cgroup v2 is available' do
      before do
        allow(File).to receive(:exist?)
          .with(described_class::CGROUP_V2_CONTROLLERS)
          .and_return(true)
        allow(File).to receive(:exist?)
          .with(described_class::CGROUP_V1_MEMORY_LIMIT)
          .and_return(false)
      end

      it 'returns :v2' do
        expect(cgroup.version).to eq(:v2)
      end

      it 'memoizes the result' do
        first_call = cgroup.version
        second_call = cgroup.version
        expect(first_call).to eq(:v2)
        expect(second_call).to eq(:v2)
        expect(first_call).to equal(second_call)
      end
    end

    context 'when cgroup v1 is available' do
      before do
        allow(File).to receive(:exist?)
          .with(described_class::CGROUP_V2_CONTROLLERS)
          .and_return(false)
        allow(File).to receive(:exist?)
          .with(described_class::CGROUP_V1_MEMORY_LIMIT)
          .and_return(true)
      end

      it 'returns :v1' do
        expect(cgroup.version).to eq(:v1)
      end
    end

    context 'when no cgroup is available' do
      before do
        allow(File).to receive(:exist?)
          .with(described_class::CGROUP_V2_CONTROLLERS)
          .and_return(false)
        allow(File).to receive(:exist?)
          .with(described_class::CGROUP_V1_MEMORY_LIMIT)
          .and_return(false)
      end

      it 'returns nil' do
        expect(cgroup.version).to be_nil
      end
    end
  end

  describe '.memory_limit' do
    context 'with cgroup v2' do
      before do
        allow(cgroup).to receive(:version).and_return(:v2)
      end

      context 'when memory limit is set' do
        before do
          allow(File).to receive(:exist?)
            .with(described_class::CGROUP_V2_MEMORY_LIMIT)
            .and_return(true)
          allow(File).to receive(:read)
            .with(described_class::CGROUP_V2_MEMORY_LIMIT)
            .and_return("#{2 * 1024 * 1024 * 1024}\n") # 2GB in bytes
        end

        it 'returns memory limit in kilobytes' do
          expect(cgroup.memory_limit).to eq(2 * 1024 * 1024) # 2GB in KB
        end
      end

      context 'when memory limit is "max" (unlimited)' do
        before do
          allow(File).to receive(:exist?)
            .with(described_class::CGROUP_V2_MEMORY_LIMIT)
            .and_return(true)
          allow(File).to receive(:read)
            .with(described_class::CGROUP_V2_MEMORY_LIMIT)
            .and_return("max\n")
        end

        it 'returns nil' do
          expect(cgroup.memory_limit).to be_nil
        end
      end

      context 'when memory limit file does not exist' do
        before do
          allow(File).to receive(:exist?)
            .with(described_class::CGROUP_V2_MEMORY_LIMIT)
            .and_return(false)
        end

        it 'returns nil' do
          expect(cgroup.memory_limit).to be_nil
        end
      end

      context 'when reading fails' do
        before do
          allow(File).to receive(:exist?)
            .with(described_class::CGROUP_V2_MEMORY_LIMIT)
            .and_return(true)
          allow(File).to receive(:read)
            .with(described_class::CGROUP_V2_MEMORY_LIMIT)
            .and_raise(StandardError)
        end

        it 'returns nil' do
          expect(cgroup.memory_limit).to be_nil
        end
      end
    end

    context 'with cgroup v1' do
      before do
        allow(cgroup).to receive(:version).and_return(:v1)
      end

      context 'when memory limit is set' do
        before do
          allow(File).to receive(:exist?)
            .with(described_class::CGROUP_V1_MEMORY_LIMIT)
            .and_return(true)
          allow(File).to receive(:read)
            .with(described_class::CGROUP_V1_MEMORY_LIMIT)
            .and_return("#{4 * 1024 * 1024 * 1024}\n") # 4GB in bytes
        end

        it 'returns memory limit in kilobytes' do
          expect(cgroup.memory_limit).to eq(4 * 1024 * 1024) # 4GB in KB
        end
      end

      context 'when memory limit is very large (unlimited)' do
        before do
          allow(File).to receive(:exist?)
            .with(described_class::CGROUP_V1_MEMORY_LIMIT)
            .and_return(true)
          # Very large value indicating unlimited
          allow(File).to receive(:read)
            .with(described_class::CGROUP_V1_MEMORY_LIMIT)
            .and_return("#{2**62}\n")
        end

        it 'returns nil' do
          expect(cgroup.memory_limit).to be_nil
        end
      end

      context 'when memory limit file does not exist' do
        before do
          allow(File).to receive(:exist?)
            .with(described_class::CGROUP_V1_MEMORY_LIMIT)
            .and_return(false)
        end

        it 'returns nil' do
          expect(cgroup.memory_limit).to be_nil
        end
      end

      context 'when reading fails' do
        before do
          allow(File).to receive(:exist?)
            .with(described_class::CGROUP_V1_MEMORY_LIMIT)
            .and_return(true)
          allow(File).to receive(:read)
            .with(described_class::CGROUP_V1_MEMORY_LIMIT)
            .and_raise(Errno::EACCES)
        end

        it 'returns nil' do
          expect(cgroup.memory_limit).to be_nil
        end
      end
    end

    context 'when no cgroup version is detected' do
      before do
        allow(cgroup).to receive(:version).and_return(nil)
      end

      it 'returns nil' do
        expect(cgroup.memory_limit).to be_nil
      end
    end
  end

  describe '.cpu_limit' do
    context 'with cgroup v2' do
      before do
        allow(cgroup).to receive(:version).and_return(:v2)
      end

      context 'when CPU quota is set' do
        before do
          allow(File).to receive(:exist?)
            .with(described_class::CGROUP_V2_CPU_MAX)
            .and_return(true)
          # 150000 quota / 100000 period = 1.5 CPUs
          allow(File).to receive(:read)
            .with(described_class::CGROUP_V2_CPU_MAX)
            .and_return("150000 100000\n")
        end

        it 'returns CPU limit as number of CPUs' do
          expect(cgroup.cpu_limit).to eq(1.5)
        end
      end

      context 'when CPU quota is "max" (unlimited)' do
        before do
          allow(File).to receive(:exist?)
            .with(described_class::CGROUP_V2_CPU_MAX)
            .and_return(true)
          allow(File).to receive(:read)
            .with(described_class::CGROUP_V2_CPU_MAX)
            .and_return("max 100000\n")
        end

        it 'returns nil' do
          expect(cgroup.cpu_limit).to be_nil
        end
      end

      context 'when CPU limit file does not exist' do
        before do
          allow(File).to receive(:exist?)
            .with(described_class::CGROUP_V2_CPU_MAX)
            .and_return(false)
        end

        it 'returns nil' do
          expect(cgroup.cpu_limit).to be_nil
        end
      end

      context 'when reading fails' do
        before do
          allow(File).to receive(:exist?)
            .with(described_class::CGROUP_V2_CPU_MAX)
            .and_return(true)
          allow(File).to receive(:read)
            .with(described_class::CGROUP_V2_CPU_MAX)
            .and_raise(StandardError)
        end

        it 'returns nil' do
          expect(cgroup.cpu_limit).to be_nil
        end
      end
    end

    context 'with cgroup v1' do
      before do
        allow(cgroup).to receive(:version).and_return(:v1)
      end

      # cpu.shares is a relative weight, not an absolute limit
      # The current implementation returns nil for v1
      it 'returns nil' do
        expect(cgroup.cpu_limit).to be_nil
      end
    end

    context 'when no cgroup version is detected' do
      before do
        allow(cgroup).to receive(:version).and_return(nil)
      end

      it 'returns nil' do
        expect(cgroup.cpu_limit).to be_nil
      end
    end
  end
end
