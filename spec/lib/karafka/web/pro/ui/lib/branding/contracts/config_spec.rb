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
  subject(:contract) { described_class.new }

  let(:params) do
    {
      ui: {
        branding: {
          type: :warning,
          label: 'Valid Label',
          notice: 'Valid Notice'
        }
      }
    }
  end

  context 'when all values are valid' do
    it 'is valid' do
      expect(contract.call(params)).to be_success
    end
  end

  context 'when branding type is invalid' do
    before { params[:ui][:branding][:type] = 'invalid_type' }

    it 'is not valid' do
      expect(contract.call(params)).not_to be_success
    end
  end

  context 'when label is nil' do
    before { params[:ui][:branding][:label] = nil }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when label is false' do
    before { params[:ui][:branding][:label] = false }

    it 'is valid' do
      expect(contract.call(params)).to be_success
    end
  end

  context 'when label is an empty string' do
    before { params[:ui][:branding][:label] = '' }

    it 'is not valid' do
      expect(contract.call(params)).not_to be_success
    end
  end

  context 'when notice is nil' do
    before { params[:ui][:branding][:notice] = nil }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when notice is false' do
    before { params[:ui][:branding][:notice] = false }

    it 'is valid' do
      expect(contract.call(params)).to be_success
    end
  end

  context 'when notice is an empty string' do
    before { params[:ui][:branding][:notice] = '' }

    it 'is not valid' do
      expect(contract.call(params)).not_to be_success
    end
  end
end
