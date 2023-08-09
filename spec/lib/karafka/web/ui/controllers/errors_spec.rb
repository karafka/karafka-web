# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  let(:errors_topic) { create_topic }
  let(:no_errors) { 'There are no errors in this errors topic partition' }
  let(:error_report) { fixtures_file('error.json') }

  before { topics_config.errors = errors_topic }

  describe '#index' do
    context 'when needed topics are missing' do
      let(:errors_topic) { SecureRandom.uuid }

      before { get 'errors' }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when there are no errors' do
      before { get 'errors' }

      it do
        expect(response).to be_ok
        expect(body).to include(no_errors)
      end
    end

    context 'when there are only few errors' do
      before do
        produce_many(errors_topic, Array.new(3) { error_report })

        get 'errors'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(no_errors)
        expect(body).to include('shinra:1555833:4e8f7174ae53')
        expect(body.scan('StandardError:').size).to eq(3)
        expect(body).not_to include('id="pagination"')
        expect(body).to include(support_message)
        expect(body).to include('high: 3')
        expect(body).to include('low: 0')
        expect(body).to include(breadcrumbs)
      end
    end

    context 'when there are enough errors for pagination to kick in' do
      before do
        produce_many(errors_topic, Array.new(30) { error_report })

        get 'errors'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(no_errors)
        expect(body).to include('shinra:1555833:4e8f7174ae53')
        expect(body.scan('StandardError:').size).to eq(25)
        expect(body).to include('id="pagination"')
        expect(body).to include(support_message)
        expect(body).to include('high: 30')
        expect(body).to include('low: 0')
        expect(body).to include(breadcrumbs)
      end
    end

    context 'when we want to visit second offset page with pagination' do
      before do
        produce_many(errors_topic, Array.new(30) { error_report })

        get 'errors?offset=0'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(no_errors)
        expect(body).to include('shinra:1555833:4e8f7174ae53')
        expect(body.scan('StandardError:').size).to eq(25)
        expect(body).to include('id="pagination"')
        expect(body).to include(support_message)
        expect(body).to include('high: 30')
        expect(body).to include('low: 0')
        expect(body).to include(breadcrumbs)
      end
    end

    context 'when we want to visit high offset page with pagination' do
      before do
        produce_many(errors_topic, Array.new(30) { error_report })

        get 'errors?offset=29'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(no_errors)
        expect(body).to include('shinra:1555833:4e8f7174ae53')
        expect(body.scan('StandardError:').size).to eq(1)
        expect(body).to include('id="pagination"')
        expect(body).to include(support_message)
        expect(body).to include('high: 30')
        expect(body).to include('low: 0')
        expect(body).to include(breadcrumbs)
      end
    end

    context 'when we want to visit page beyond pagination' do
      before do
        produce_many(errors_topic, Array.new(30) { error_report })

        get 'errors?offset=129'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(no_errors)
        expect(body.scan('StandardError:').size).to eq(0)
        expect(body).not_to include('id="pagination"')
        expect(body).to include('high: 30')
        expect(body).to include(support_message)
        expect(body).to include('low: 0')
        expect(body).to include(breadcrumbs)
      end
    end
  end

  describe '#show' do
    context 'when visiting offset that does not exist' do
      before { get 'errors/123456' }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when visiting error that does exist' do
      before do
        produce(errors_topic, error_report)
        get 'errors/0'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(no_errors)
        expect(body).to include('shinra:1555833:4e8f7174ae53')
        expect(body.scan('StandardError').size).to eq(4)
        expect(body).not_to include('id="pagination"')
        expect(body).to include(support_message)
        expect(body).to include('This feature is available only')
        expect(body).to include(breadcrumbs)
      end
    end
  end
end
