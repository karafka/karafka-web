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
          expect(body).to include('replication factor of')
          expect(body).to include('redundant copies')
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
          expect(body).to include('replication factor of')
          expect(body).to include('acceptable for development')
          expect(body).to include('can cause data loss in production')
        end

        it 'still displays the replication settings cards' do
          expect(body).to include('Replication Factor')
          expect(body).to include('Min In-Sync Replicas')
          expect(body).to include('Fault Tolerance')
        end
      end
    end

    context 'when replication factor equals min.insync.replicas (zero fault tolerance)' do
      let(:partitions_data) { [{ replica_count: 2, leader: 1, in_sync_replica_brokers: '1,2' }] }

      let(:mock_synonym) do
        instance_double(
          Karafka::Admin::Configs::Config,
          name: 'default.replication.factor',
          value: '2',
          default?: false,
          read_only?: false,
          sensitive?: false,
          synonym?: true,
          synonyms: []
        )
      end

      let(:mock_config) do
        instance_double(
          Karafka::Admin::Configs::Config,
          name: 'min.insync.replicas',
          value: '2',
          default?: false,
          read_only?: false,
          sensitive?: false,
          synonym?: false,
          synonyms: [mock_synonym]
        )
      end

      let(:topic_model) do
        Karafka::Web::Ui::Models::Topic.new(
          topic_name: topic,
          partition_count: 2,
          partitions: partitions_data
        )
      end

      let(:distribution_result) do
        [
          Karafka::Web::Ui::Lib::HashProxy.new(std_dev: 0, std_dev_rel: 0.0, sum: 0),
          [Karafka::Web::Ui::Lib::HashProxy.new(count: 0, partition_id: 0, share: 0.0, diff: 0)]
        ]
      end

      before do
        allow(topic_model)
          .to receive_messages(configs: [mock_config], distribution: distribution_result)
        allow(Karafka::Web::Ui::Models::Topic).to receive(:find).and_call_original
        allow(Karafka::Web::Ui::Models::Topic).to receive(:find).with(topic).and_return(topic_model)
        allow(Karafka::Admin).to receive(:read_watermark_offsets).and_return([0, 100])
        allow(Karafka.env).to receive(:production?).and_return(true)

        get "topics/#{topic}/replication"
      end

      it 'displays the zero fault tolerance warning' do
        expect(response).to be_ok
        expect(body).to include('Replication Resilience Issue Detected')
        expect(body).to include('zero')
        expect(body).to include('fault tolerance')
        expect(body).to include('replication factor of')
        expect(body).to include('one')
      end

      it 'shows fault tolerance as 0 brokers' do
        expect(body).to include('0 brokers')
      end
    end

    context 'when min.insync.replicas is 1 with higher replication factor (low durability)' do
      let(:partitions_data) { [{ replica_count: 3, leader: 1, in_sync_replica_brokers: '1,2,3' }] }

      let(:mock_synonym) do
        instance_double(
          Karafka::Admin::Configs::Config,
          name: 'default.replication.factor',
          value: '3',
          default?: false,
          read_only?: false,
          sensitive?: false,
          synonym?: true,
          synonyms: []
        )
      end

      let(:mock_config) do
        instance_double(
          Karafka::Admin::Configs::Config,
          name: 'min.insync.replicas',
          value: '1',
          default?: false,
          read_only?: false,
          sensitive?: false,
          synonym?: false,
          synonyms: [mock_synonym]
        )
      end

      let(:topic_model) do
        Karafka::Web::Ui::Models::Topic.new(
          topic_name: topic,
          partition_count: 2,
          partitions: partitions_data
        )
      end

      let(:distribution_result) do
        [
          Karafka::Web::Ui::Lib::HashProxy.new(std_dev: 0, std_dev_rel: 0.0, sum: 0),
          [Karafka::Web::Ui::Lib::HashProxy.new(count: 0, partition_id: 0, share: 0.0, diff: 0)]
        ]
      end

      before do
        allow(topic_model)
          .to receive_messages(configs: [mock_config], distribution: distribution_result)
        allow(Karafka::Web::Ui::Models::Topic).to receive(:find).and_call_original
        allow(Karafka::Web::Ui::Models::Topic).to receive(:find).with(topic).and_return(topic_model)
        allow(Karafka::Admin).to receive(:read_watermark_offsets).and_return([0, 100])
        allow(Karafka.env).to receive(:production?).and_return(true)
        get "topics/#{topic}/replication"
      end

      it 'displays the low durability warning' do
        expect(response).to be_ok
        expect(body).to include('Low Data Durability Configuration')
        expect(body).to include('min.insync.replicas')
        expect(body).to include('replication factor of')
        expect(body).to include('replication to followers completes')
        expect(body).to include('permanently')
      end

      it 'shows positive fault tolerance' do
        expect(body).to include('2 broker(s)')
      end
    end

    context 'when configuration is healthy (RF > minISR and minISR > 1)' do
      let(:partitions_data) { [{ replica_count: 3, leader: 1, in_sync_replica_brokers: '1,2,3' }] }

      let(:mock_synonym) do
        instance_double(
          Karafka::Admin::Configs::Config,
          name: 'default.replication.factor',
          value: '3',
          default?: false,
          read_only?: false,
          sensitive?: false,
          synonym?: true,
          synonyms: []
        )
      end

      let(:mock_config) do
        instance_double(
          Karafka::Admin::Configs::Config,
          name: 'min.insync.replicas',
          value: '2',
          default?: false,
          read_only?: false,
          sensitive?: false,
          synonym?: false,
          synonyms: [mock_synonym]
        )
      end

      let(:topic_model) do
        Karafka::Web::Ui::Models::Topic.new(
          topic_name: topic,
          partition_count: 2,
          partitions: partitions_data
        )
      end

      let(:distribution_result) do
        [
          Karafka::Web::Ui::Lib::HashProxy.new(std_dev: 0, std_dev_rel: 0.0, sum: 0),
          [Karafka::Web::Ui::Lib::HashProxy.new(count: 0, partition_id: 0, share: 0.0, diff: 0)]
        ]
      end

      before do
        allow(topic_model)
          .to receive_messages(configs: [mock_config], distribution: distribution_result)
        allow(Karafka::Web::Ui::Models::Topic).to receive(:find).and_call_original
        allow(Karafka::Web::Ui::Models::Topic).to receive(:find).with(topic).and_return(topic_model)
        allow(Karafka::Admin).to receive(:read_watermark_offsets).and_return([0, 100])
        get "topics/#{topic}/replication"
      end

      it 'displays the success message' do
        expect(response).to be_ok
        expect(body).to include('Replication Configuration is Fault Tolerant')
        expect(body).to include('broker failure')
      end

      it 'shows positive fault tolerance' do
        expect(body).to include('1 broker(s)')
      end
    end
  end
end
