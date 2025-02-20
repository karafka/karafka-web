# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:topic) { create_topic(partitions: partitions) }
  let(:partitions) { 1 }

  describe '#show' do
    let(:no_data_msg) { 'Those partitions are empty and do not contain any data' }
    let(:many_partitions_msg) { 'distribution results are computed based only' }

    context 'when trying to read distribution of a non-existing topic' do
      before { get "topics/#{generate_topic_name}/distribution" }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when getting distribution of an existing empty topic' do
      before { get "topics/#{topic}/distribution" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include(no_data_msg)
      end
    end

    context 'when getting distribution of an existing empty topic with multiple partitions' do
      let(:partitions) { 100 }

      before { get "topics/#{topic}/distribution" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include(no_data_msg)
        expect(body).to include(many_partitions_msg)
      end
    end

    context 'when getting distribution of an existing topic with one partition and data' do
      before do
        produce_many(topic, Array.new(100, ''))
        get "topics/#{topic}/distribution"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include('100.0%')
        expect(body).not_to include(no_data_msg)
      end
    end

    context 'when getting distribution of an existing topic with few partitions and data' do
      let(:partitions) { 5 }

      before do
        5.times { |i| produce_many(topic, Array.new(100, ''), partition: i) }

        get "topics/#{topic}/distribution"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include('20.0%')
        expect(body).not_to include(no_data_msg)
        expect(body).not_to include(many_partitions_msg)
      end
    end

    context 'when getting distribution of an existing topic with many partitions and data' do
      let(:partitions) { 100 }

      before do
        100.times { |i| produce_many(topic, Array.new(10, ''), partition: i) }

        get "topics/#{topic}/distribution"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include('4.0%')
        expect(body).not_to include(no_data_msg)
        expect(body).to include(many_partitions_msg)
      end
    end

    context 'when getting distribution of a topic with many partitions and data page 2' do
      let(:partitions) { 100 }

      before do
        100.times { |i| produce_many(topic, Array.new(10, ''), partition: i) }

        get "topics/#{topic}/distribution?page=2"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include('4.0%')
        expect(body).to include('/25">')
        expect(body).not_to include(no_data_msg)
        expect(body).to include(many_partitions_msg)
      end
    end
  end
end
