# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::Pro::App }

  describe '#index' do
    before { get 'explorer' }

    it do
      expect(response).to be_ok
      expect(body).to include(breadcrumbs)
      expect(body).not_to include(pagination)
      expect(body).not_to include(support_message)
      expect(body).to include(topics_config.consumers.states)
      expect(body).to include(topics_config.consumers.metrics)
      expect(body).to include(topics_config.consumers.reports)
      expect(body).to include(topics_config.errors)
    end

    context 'when there are no topics' do
      before do
        allow(::Karafka::Web::Ui::Models::ClusterInfo).to receive(:topics).and_return([])
        get 'explorer'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('There are no available topics in the current cluster')
      end
    end
  end

  describe '#topic' do
    pending
  end

  describe '#partition' do
    pending
  end

  describe '#show' do
    pending
  end

  describe '#recent' do
    pending
  end
end
