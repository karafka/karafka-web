# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

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
