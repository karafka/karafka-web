# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  describe '#index' do
    before { get 'cluster' }

    it do
      expect(response).to be_ok
      expect(body).to include(support_message)
      expect(body).to include(breadcrumbs)
    end

    context 'when there are many pages with topics' do
      before { 30.times { create_topic } }

      context 'when we visit existing page' do
        before { get 'cluster?page=2' }

        it do
          expect(response).to be_ok
          expect(body).to include(support_message)
          expect(body).to include(breadcrumbs)
          expect(body).to include(pagination)
        end
      end

      context 'when we visit a non-existing page' do
        before { get 'cluster?page=100000000' }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).to include(support_message)
          expect(body).to include(no_meaningful_results)
        end
      end
    end
  end
end
