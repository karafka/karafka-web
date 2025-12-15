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

    context 'when getting replication of an existing topic with single partition' do
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

      it 'shows partition details' do
        expect(body).to include('Partition')
        expect(body).to include('Leader')
        expect(body).to include('0') # First partition
      end

      it 'displays replication settings cards' do
        expect(body).to include('Replication Factor')
        expect(body).to include('Min In-Sync Replicas')
        expect(body).to include('Fault Tolerance')
      end
    end

    context 'when topic has multiple partitions' do
      let(:partitions) { 5 }

      before { get "topics/#{topic}/replication" }

      it 'displays all partitions' do
        expect(response).to be_ok
        expect(body).to include(topic)
        expect(body).to include('0')
        expect(body).to include('1')
        expect(body).to include('2')
        expect(body).to include('3')
        expect(body).to include('4')
      end

      it 'shows replication details for each partition' do
        expect(body).to include('Replica Count')
        expect(body).to include('In Sync Brokers')
        expect(body).to include('Leader')
      end
    end

    context 'when replication factor is 1 (no redundancy)' do
      # In the test environment, RF=1 by default (single broker setup)
      # This triggers the no redundancy warning

      context 'when in production environment' do
        before do
          allow(Karafka.env).to receive(:production?).and_return(true)
          get "topics/#{topic}/replication"
        end

        it 'displays the no redundancy warning with production severity' do
          expect(response).to be_ok
          expect(body).to include('No Replication Redundancy')
          expect(body).to include('replication factor of 1')
          expect(body).to include('no redundant copies')
          expect(body).to include('permanently lost')
          expect(body).to include('Broker Failures and Fault Tolerance')
          expect(body).to include('critical issue')
        end

        it 'shows fault tolerance as 0 brokers' do
          expect(body).to include('0 brokers')
        end
      end

      context 'when not in production environment' do
        before do
          allow(Karafka.env).to receive(:production?).and_return(false)
          get "topics/#{topic}/replication"
        end

        it 'displays the no redundancy warning with development context' do
          expect(response).to be_ok
          expect(body).to include('No Replication Redundancy')
          expect(body).to include('replication factor of 1')
          expect(body).to include('acceptable for development')
          expect(body).to include('would cause data loss in production')
        end

        it 'still displays the replication settings cards' do
          expect(body).to include('Replication Factor')
          expect(body).to include('Min In-Sync Replicas')
          expect(body).to include('Fault Tolerance')
        end
      end
    end
  end
end
