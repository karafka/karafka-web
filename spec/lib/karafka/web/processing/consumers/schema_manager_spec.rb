# frozen_string_literal: true

RSpec.describe_current do
  subject(:manager) { described_class.new }

  let(:message) do
    Struct.new(:payload).new(
      { schema_version: schema_version }
    )
  end

  describe '#initialize' do
    it 'initializes as compatible' do
      expect(manager.to_s).to eq('compatible')
    end
  end

  describe '#call' do
    context 'when manager is in compatible state' do
      context 'when it is the same version as in the process' do
        let(:schema_version) { Karafka::Web::Tracking::Consumers::Sampler::SCHEMA_VERSION }

        it 'returns :current' do
          expect(manager.call(message)).to eq(:current)
        end

        it 'remains compatible after processing' do
          manager.call(message)
          expect(manager.to_s).to eq('compatible')
        end
      end

      context 'when it is an older version' do
        let(:schema_version) { '1.1.0' }

        it 'returns :older' do
          expect(manager.call(message)).to eq(:older)
        end

        it 'remains compatible after processing' do
          manager.call(message)
          expect(manager.to_s).to eq('compatible')
        end
      end

      context 'when it is a newer version' do
        let(:schema_version) { '111.1.0' }

        it 'returns :newer' do
          expect(manager.call(message)).to eq(:newer)
        end

        it 'remains compatible after processing' do
          manager.call(message)
          expect(manager.to_s).to eq('compatible')
        end
      end

      context 'when schema version is nil' do
        let(:schema_version) { nil }

        it 'returns :older when comparing nil version' do
          expect(manager.call(message)).to eq(:older)
        end
      end

      context 'when schema version is empty string' do
        let(:schema_version) { '' }

        it 'returns :older when comparing empty version' do
          expect(manager.call(message)).to eq(:older)
        end
      end

      context 'when schema version has pre-release suffix' do
        let(:schema_version) { '2.0.0-alpha' }

        it 'handles pre-release versions correctly' do
          expect(manager.call(message)).to eq(:newer)
        end
      end
    end

    context 'when manager is in incompatible state' do
      before { manager.invalidate! }

      let(:schema_version) { Karafka::Web::Tracking::Consumers::Sampler::SCHEMA_VERSION }

      it 'still returns version comparison result' do
        result = manager.call(message)
        expect(result).to eq(:current)
      end

      it 'remains incompatible after processing' do
        manager.call(message)
        expect(manager.to_s).to eq('incompatible')
      end
    end

    context 'with malformed version strings' do
      let(:schema_version) { 'not-a-version' }

      it 'raises error for malformed versions' do
        expect { manager.call(message) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#invalidate!' do
    it 'changes state to incompatible' do
      expect { manager.invalidate! }
        .to change(manager, :to_s).from('compatible').to('incompatible')
    end

    it 'is idempotent' do
      manager.invalidate!
      manager.invalidate!
      expect(manager.to_s).to eq('incompatible')
    end
  end

  describe 'state management' do
    it 'starts as compatible' do
      expect(manager.to_s).to eq('compatible')
    end

    it 'becomes incompatible after invalidation' do
      manager.invalidate!
      expect(manager.to_s).to eq('incompatible')
    end
  end

  describe '#to_s' do
    it 'returns compatible string representation' do
      expect(manager.to_s).to eq('compatible')
    end

    context 'when after invalidation' do
      before { manager.invalidate! }

      it 'returns incompatible string representation' do
        expect(manager.to_s).to eq('incompatible')
      end
    end
  end

  describe 'version comparison behavior' do
    let(:current_version) { Karafka::Web::Tracking::Consumers::Sampler::SCHEMA_VERSION }

    context 'with semantic versioning' do
      it 'correctly identifies older major versions' do
        major_parts = current_version.split('.')
        older_major = "#{major_parts[0].to_i - 1}.#{major_parts[1]}.#{major_parts[2]}"

        message = Struct.new(:payload).new({ schema_version: older_major })
        expect(manager.call(message)).to eq(:older)
      end

      it 'correctly identifies newer major versions' do
        major_parts = current_version.split('.')
        newer_major = "#{major_parts[0].to_i + 1}.#{major_parts[1]}.#{major_parts[2]}"

        message = Struct.new(:payload).new({ schema_version: newer_major })
        expect(manager.call(message)).to eq(:newer)
      end

      it 'correctly identifies older minor versions' do
        parts = current_version.split('.')
        older_minor = "#{parts[0]}.#{parts[1].to_i - 1}.#{parts[2]}"

        message = Struct.new(:payload).new({ schema_version: older_minor })
        expect(manager.call(message)).to eq(:older)
      end

      it 'correctly identifies newer minor versions' do
        parts = current_version.split('.')
        newer_minor = "#{parts[0]}.#{parts[1].to_i + 1}.#{parts[2]}"

        message = Struct.new(:payload).new({ schema_version: newer_minor })
        expect(manager.call(message)).to eq(:newer)
      end

      it 'correctly identifies older patch versions' do
        parts = current_version.split('.')
        older_patch = "#{parts[0]}.#{parts[1]}.#{parts[2].to_i - 1}"

        message = Struct.new(:payload).new({ schema_version: older_patch })
        expect(manager.call(message)).to eq(:older)
      end

      it 'correctly identifies newer patch versions' do
        parts = current_version.split('.')
        newer_patch = "#{parts[0]}.#{parts[1]}.#{parts[2].to_i + 1}"

        message = Struct.new(:payload).new({ schema_version: newer_patch })
        expect(manager.call(message)).to eq(:newer)
      end
    end

    context 'with edge case versions' do
      it 'handles version 0.0.0' do
        message = Struct.new(:payload).new({ schema_version: '0.0.0' })
        expect(manager.call(message)).to eq(:older)
      end

      it 'handles very high version numbers' do
        message = Struct.new(:payload).new({ schema_version: '999.999.999' })
        expect(manager.call(message)).to eq(:newer)
      end

      it 'handles single digit versions' do
        message = Struct.new(:payload).new({ schema_version: '1' })
        result = manager.call(message)
        expect(%i[older newer current] & [result]).not_to be_empty
      end

      it 'handles two-part versions' do
        message = Struct.new(:payload).new({ schema_version: '1.0' })
        result = manager.call(message)
        expect(%i[older newer current] & [result]).not_to be_empty
      end
    end
  end

  describe 'state consistency' do
    it 'maintains consistent state across multiple calls' do
      current_version_message = Struct.new(:payload).new(
        { schema_version: Karafka::Web::Tracking::Consumers::Sampler::SCHEMA_VERSION }
      )

      5.times do
        expect(manager.call(current_version_message)).to eq(:current)
        expect(manager.to_s).to eq('compatible')
      end
    end

    it 'maintains incompatible state after invalidation across calls' do
      manager.invalidate!
      current_version_message = Struct.new(:payload).new(
        { schema_version: Karafka::Web::Tracking::Consumers::Sampler::SCHEMA_VERSION }
      )

      5.times do
        expect(manager.call(current_version_message)).to eq(:current)
        expect(manager.to_s).to eq('incompatible')
      end
    end
  end
end
