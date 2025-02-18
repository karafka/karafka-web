# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:topic) { create_topic(partitions: partitions) }
  let(:partitions) { 1 }

  describe '#show' do
    context 'when trying to read configs of a non-existing topic' do
      before { get "topics/#{generate_topic_name}/config" }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when getting configs of an existing topic' do
      before { get "topics/#{topic}/config" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include(topic)
        expect(body).to include('max.message.bytes')
        expect(body).to include('retention.ms')
        expect(body).to include('min.insync.replicas')
      end
    end
  end
end
