# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:topic) { create_topic(partitions: partitions) }
  let(:partitions) { 1 }

  describe '#show' do
    context 'when trying to read offsets of a non-existing topic' do
      before { get "topics/#{generate_topic_name}/offsets" }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when getting offsets of an existing empty topic' do
      before { get "topics/#{topic}/offsets" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include(topic)
        expect(body).to include('<table class="data-table">')
        expect(body.scan('<tr>').size).to eq(2)
      end
    end

    context 'when getting offsets of an existing empty topic with multiple partitions' do
      let(:partitions) { 100 }

      before { get "topics/#{topic}/offsets" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include(topic)
        expect(body).to include('<table class="data-table">')
        expect(body.scan('<tr>').size).to eq(26)
      end
    end

    context 'when getting offsets of an existing topic with one partition and data' do
      before do
        produce_many(topic, Array.new(100, ''))
        get "topics/#{topic}/offsets"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('<table class="data-table">')
        expect(body).to include(topic)
        expect(body.scan('<tr>').size).to eq(2)
        expect(body.scan('<td>100</td>').size).to eq(2)
      end
    end

    context 'when getting offsets of a topic with many partitions and data page 2' do
      let(:partitions) { 100 }

      before do
        100.times { |i| produce_many(topic, Array.new(10, ''), partition: i) }

        get "topics/#{topic}/offsets?page=2"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('<table class="data-table">')
        expect(body).to include(topic)
        expect(body.scan('<tr>').size).to eq(26)
        expect(body.scan('<td>10</td>').size).to eq(50)
      end
    end
  end
end
