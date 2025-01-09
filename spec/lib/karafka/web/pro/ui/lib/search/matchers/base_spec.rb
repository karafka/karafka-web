# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  let(:matcher_class) { described_class }

  describe '.active?' do
    it { expect(matcher_class.active?(rand.to_s)).to be(true) }
  end

  describe '.name' do
    it 'returns the name of the matcher based on the class name' do
      expect(matcher_class.name).to eq('Base')
    end

    context 'when the class name has multiple words' do
      let(:matcher_class) do
        Class.new(Karafka::Web::Pro::Ui::Lib::Search::Matchers::Base) do
          def self.to_s
            'Karafka::Web::Pro::Ui::Lib::Search::Matchers::CustomMatcher'
          end
        end
      end

      it 'returns the name with spaces between words' do
        expect(matcher_class.name).to eq('Custom matcher')
      end
    end
  end

  describe '#call' do
    let(:matcher_instance) { matcher_class.new }
    let(:phrase) { 'test phrase' }
    let(:message) { instance_double(Karafka::Messages::Message) }

    it 'raises NotImplementedError' do
      expect { matcher_instance.call(phrase, message) }
        .to raise_error(NotImplementedError, 'Implement in a subclass')
    end
  end
end
