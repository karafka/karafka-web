# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:topic) { create_topic(partitions: partitions) }
  let(:partitions) { 1 }

  describe '#show' do
    context 'when trying to read configs of a non-existing topic' do
      before { get "topics/#{generate_topic_name}/replication" }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when getting replication of an existing topic' do
      before { get "topics/#{topic}/replication" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include(topic)
        expect(body).to include('Replica Count')
        expect(body).to include('In Sync Brokers')
      end
    end
  end
end
