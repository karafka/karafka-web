# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::Pro::App }

  describe 'cluster/ path redirect' do
    context 'when visiting the cluster/ path without type indicator' do
      before { get 'cluster' }

      it 'expect to redirect to brokers page' do
        expect(response.status).to eq(302)
        expect(response.headers['location']).to include('cluster/brokers')
      end
    end
  end

  describe '#brokers' do
    before { get 'cluster/brokers' }

    it do
      expect(response).to be_ok
      expect(body).to include('Id')
      expect(body).to include(breadcrumbs)
      expect(body).not_to include(support_message)
    end
  end

  describe '#replication' do
    before { get 'cluster/replication' }

    it do
      expect(response).to be_ok
      expect(body).to include(breadcrumbs)
      expect(body).not_to include(support_message)
    end

    context 'when there are many pages with topics' do
      before { 30.times { create_topic } }

      context 'when we visit existing page' do
        before { get 'cluster/replication?page=2' }

        it do
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).to include(pagination)
          expect(body).not_to include(support_message)
        end
      end

      context 'when we visit a non-existing page' do
        before { get 'cluster/replication?page=100000000' }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).to include(no_meaningful_results)
          expect(body).not_to include(support_message)
        end
      end
    end
  end
end
