# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  describe '#index' do
    before { get 'cluster' }

    it do
      expect(response).to be_ok
      expect(body).to include('ID')
      expect(body).to include(breadcrumbs)
      expect(body).not_to include(support_message)
    end

    context 'when requests policy prevents us from visiting this page' do
      before do
        allow(::Karafka::Web.config.ui.policies.requests)
          .to receive(:allow?)
          .and_return(false)

        get 'cluster'
      end

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(403)
      end
    end
  end

  describe '#show' do
    context 'when broker with given id does not exist' do
      before { get 'cluster/123' }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when broker with given id exists' do
      before { get 'cluster/1' }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(support_message)
        expect(body).to include('advertised.listeners')
        expect(body).to include('controller.quota.window.num')
        expect(body).to include('log.flush.interval.ms')
        expect(body).to include('9223372036854775807')
      end
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
