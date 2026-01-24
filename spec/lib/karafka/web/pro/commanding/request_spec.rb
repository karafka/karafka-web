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
  subject(:request) { described_class.new(details) }

  let(:details) do
    {
      name: command_name,
      additional: 'value'
    }
  end

  let(:command_name) { 'test_command' }

  describe '#name' do
    it 'returns the command name from details' do
      expect(request.name).to eq(command_name)
    end

    context 'when name is missing from details' do
      let(:details) { {} }

      it 'raises KeyError' do
        expect { request.name }.to raise_error(KeyError)
      end
    end
  end

  describe '#[]' do
    context 'when key exists' do
      it 'returns the value for given key' do
        expect(request[:additional]).to eq('value')
      end
    end

    context 'when key does not exist' do
      it 'raises KeyError' do
        expect { request[:non_existent] }.to raise_error(KeyError)
      end
    end
  end

  describe '#to_h' do
    it 'returns the original details hash' do
      expect(request.to_h).to eq(details)
    end

    it 'returns the same object that was passed to initialize' do
      expect(request.to_h).to be(details)
    end
  end

  describe '#initialize' do
    context 'when initialized with empty hash' do
      let(:details) { {} }

      it 'creates instance without errors' do
        expect { request }.not_to raise_error
      end
    end

    context 'when initialized with nil' do
      let(:details) { nil }

      it 'raises NoMethodError' do
        expect { request[:anything] }.to raise_error(NoMethodError)
      end
    end
  end
end
