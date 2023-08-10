# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::Pro::App }

  let(:topic) { create_topic(partitions: partitions) }
  let(:partitions) { 1 }

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
    context 'when we view topic without any messages' do
      before { get "explorer/#{topic}" }

      it do
        expect(response).to be_ok
        expect(body).to include('This topic is empty and does not contain any data')
        expect(body).to include('total: 1')
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when we view first page from a topic with one partition with data' do
      before do
        produce_many(topic, Array.new(30, '1'))
        get "explorer/#{topic}"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).to include("#{topic}/0/5")
        expect(body).to include("#{topic}/0/29")
        expect(body).not_to include("#{topic}/0/30")
        expect(body).not_to include("#{topic}/0/4")
        expect(body).not_to include(support_message)
      end
    end

    context 'when we view last page from a topic with one partition with data' do
      before do
        produce_many(topic, Array.new(30, '1'))
        get "explorer/#{topic}?page=2"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).to include("#{topic}/0/4")
        expect(body).not_to include("#{topic}/0/30")
        expect(body).not_to include("#{topic}/0/5")
        expect(body).not_to include("#{topic}/0/29")
        expect(body).not_to include(support_message)
      end
    end

    context 'when we view first page from a topic with many partitions' do
      let(:partitions) { 5 }

      before do
        partitions.times { |i| produce_many(topic, Array.new(30, '1'), partition: i) }
        get "explorer/#{topic}"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)

        partitions.times do |i|
          expect(body).to include("#{topic}/#{i}/29")
          expect(body).to include("#{topic}/#{i}/28")
          expect(body).to include("#{topic}/#{i}/27")
          expect(body).to include("#{topic}/#{i}/26")
          expect(body).to include("#{topic}/#{i}/25")
          expect(body).not_to include("#{topic}/#{i}/24")
          expect(body).not_to include("#{topic}/#{i}/30")
        end

        expect(body).not_to include(support_message)
      end
    end

    context 'when we view last page from a topic with many partitions' do
      let(:partitions) { 5 }

      before do
        partitions.times { |i| produce_many(topic, Array.new(30, '1'), partition: i) }
        get "explorer/#{topic}?page=6"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)

        partitions.times do |i|
          expect(body).to include("#{topic}/#{i}/4")
          expect(body).to include("#{topic}/#{i}/3")
          expect(body).to include("#{topic}/#{i}/2")
          expect(body).to include("#{topic}/#{i}/1")
          expect(body).to include("#{topic}/#{i}/0")
          expect(body).not_to include("#{topic}/#{i}/5")
          expect(body).not_to include("#{topic}/#{i}/6")
        end

        expect(body).not_to include(support_message)
      end
    end

    context 'when we request a page above available elements' do
      before do
        produce_many(topic, Array.new(30, '1'))
        get "explorer/#{topic}?page=100"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).to include(no_meaningful_results)
        expect(body).not_to include(support_message)
      end
    end
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
