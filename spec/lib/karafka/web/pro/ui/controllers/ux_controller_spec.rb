# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  describe '#show' do
    before { get 'ux' }

    it do
      expect(response).to be_ok
      expect(body).not_to include(support_message)
      expect(body).to include(breadcrumbs)
    end
  end

  # We test branding here because it does not require us to create topics
  describe 'branding concept' do
    let(:branding_cfg) { Karafka::Web.config.ui.branding }
    let(:type) { :info }
    let(:label) { 'branding_label' }
    let(:notice) { 'branding_notice' }

    before do
      branding_cfg.type = type
      branding_cfg.label = label
      branding_cfg.notice = notice

      get 'ux'
    end

    after do
      branding_cfg.type = :info
      branding_cfg.label = false
      branding_cfg.notice = false
    end

    context 'when there is no label or notice' do
      let(:label) { false }
      let(:notice) { false }

      it 'expect not to have them' do
        expect(body).not_to include('branding_label')
        expect(body).not_to include('branding_notice')
      end
    end

    context 'when there is only info label' do
      let(:notice) { false }

      it 'expect to have only label' do
        expect(body).to include('branding_label')
        expect(body).not_to include('branding_notice')
      end
    end

    context 'when there is only info notice' do
      let(:label) { false }

      it 'expect to have only notice' do
        expect(body).to include('branding_notice')
        expect(body).not_to include('branding_label')
      end
    end

    context 'when there is notice and label' do
      it 'expect to have both' do
        expect(body).to include('branding_notice')
        expect(body).to include('branding_label')
      end
    end

    context 'when there is notice and label in warning' do
      let(:type) { :warning }

      it 'expect to have both' do
        expect(body).to include('branding_notice')
        expect(body).to include('branding_label')
      end
    end
  end
end
