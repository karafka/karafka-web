# frozen_string_literal: true

RSpec.describe Karafka::Web::Ui::Base, type: :controller do
  subject(:app) { Karafka::Web::Ui::App }

  let(:monitor) { Karafka.monitor }

  describe 'error handling and reporting' do
    context 'when an unhandled error occurs in the UI' do
      before do
        controller = instance_double(
          Karafka::Web::Ui::Controllers::DashboardController
        ).as_null_object
        allow(Karafka::Web::Ui::Controllers::DashboardController)
          .to receive(:new)
          .and_return(controller)
        allow(controller)
          .to receive(:index)
          .and_raise(StandardError, 'Unexpected error in UI')
      end

      it 'expect to report the error to Karafka monitoring and show 500 page' do
        allow(monitor).to receive(:instrument).and_call_original

        get 'dashboard'

        expect(monitor).to have_received(:instrument) do |event, payload|
          expect(event).to eq('error.occurred')
          expect(payload[:type]).to eq('web.ui.error')
          expect(payload[:error]).to be_a(StandardError)
          expect(payload[:error].message).to eq('Unexpected error in UI')
        end

        expect(status).to eq(500)
        expect(body).to include('500')
        expect(body).to include('Internal Server Error')
      end
    end

    context 'when a UI::NotFoundError occurs' do
      before do
        controller = instance_double(
          Karafka::Web::Ui::Controllers::DashboardController
        ).as_null_object
        allow(Karafka::Web::Ui::Controllers::DashboardController)
          .to receive(:new)
          .and_return(controller)
        allow(controller)
          .to receive(:index)
          .and_raise(Karafka::Web::Errors::Ui::NotFoundError, 'Not found')
      end

      it 'expect not to report the error to Karafka monitoring' do
        allow(monitor).to receive(:instrument).and_call_original

        get 'dashboard'

        expect(monitor).not_to have_received(:instrument)
        expect(status).to eq(404)
      end
    end

    context 'when a UI::ProOnlyError occurs' do
      before do
        controller = instance_double(
          Karafka::Web::Ui::Controllers::DashboardController
        ).as_null_object
        allow(Karafka::Web::Ui::Controllers::DashboardController)
          .to receive(:new)
          .and_return(controller)
        allow(controller)
          .to receive(:index)
          .and_raise(Karafka::Web::Errors::Ui::ProOnlyError, 'Pro only')
      end

      it 'expect not to report the error to Karafka monitoring' do
        allow(monitor).to receive(:instrument).and_call_original

        get 'dashboard'

        expect(monitor).not_to have_received(:instrument)
        expect(status).to eq(402)
      end
    end

    context 'when a UI::ForbiddenError occurs' do
      before do
        controller = instance_double(
          Karafka::Web::Ui::Controllers::DashboardController
        ).as_null_object
        allow(Karafka::Web::Ui::Controllers::DashboardController)
          .to receive(:new)
          .and_return(controller)
        allow(controller)
          .to receive(:index)
          .and_raise(Karafka::Web::Errors::Ui::ForbiddenError, 'Forbidden')
      end

      it 'expect not to report the error to Karafka monitoring' do
        allow(monitor).to receive(:instrument).and_call_original

        get 'dashboard'

        expect(monitor).not_to have_received(:instrument)
        expect(status).to eq(403)
      end
    end

    context 'when a RdkafkaError occurs' do
      before do
        controller = instance_double(
          Karafka::Web::Ui::Controllers::DashboardController
        ).as_null_object
        allow(Karafka::Web::Ui::Controllers::DashboardController)
          .to receive(:new)
          .and_return(controller)
        allow(controller)
          .to receive(:index)
          .and_raise(Rdkafka::RdkafkaError.new(1, broker_message: 'Kafka error'))
      end

      it 'expect not to report the error to Karafka monitoring' do
        allow(monitor).to receive(:instrument).and_call_original

        get 'dashboard'

        expect(monitor).not_to have_received(:instrument)
        expect(status).to eq(404)
      end
    end
  end

  describe 'session path tracking' do
    let(:env_key) { Karafka::Web.config.ui.sessions.env_key }

    context 'when navigating between pages' do
      before do
        get 'dashboard'
        get 'consumers'
      end

      it 'expect to store paths with string keys' do
        session = last_request.env[env_key]

        expect(session['current_path']).to eq('/consumers')
        expect(session['previous_path']).to eq('/dashboard')
        # Ensure symbol keys are not used
        expect(session[:current_path]).to be_nil
        expect(session[:previous_path]).to be_nil
      end
    end

    context 'when visiting the first page' do
      before { get 'dashboard' }

      it 'expect to set current_path with string key' do
        session = last_request.env[env_key]

        expect(session['current_path']).to eq('/dashboard')
        expect(session['previous_path']).to be_nil
      end
    end
  end
end
