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

  let(:states_topic) { create_topic }
  let(:reports_topic) { create_topic }

  describe '#running_jobs' do
    context 'when process has jobs but not running' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report['jobs'][0]['status'] = 'pending'

        produce(states_topic, Fixtures.consumers_states_file)
        produce(reports_topic, report.to_json)

        get 'consumers/shinra:1:1/jobs/running'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('This process has no running jobs at the moment')
        expect(body).not_to include('Karafka::Pro::ActiveJob::Consumer')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when process has running jobs' do
      before { get 'consumers/shinra:1:1/jobs/running' }

      it do
        expect(response).to be_ok
        expect(body).to include('Karafka::Pro::ActiveJob::Consumer')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when process has jobs reported in a transactional fashion' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get 'consumers/shinra:1:1/jobs/running'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('Karafka::Pro::ActiveJob::Consumer')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when given process has no jobs running' do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report['jobs'] = []

        produce(reports_topic, report.to_json)

        get 'consumers/shinra:1:1/jobs/running'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('This process has no running jobs at the moment')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when given process does not exist' do
      before { get 'consumers/4e8f7174ae53/jobs/running' }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end
  end

  describe '#pending_jobs' do
    context 'when process has jobs but not pending' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report['jobs'][0]['status'] = 'running'

        produce(states_topic, Fixtures.consumers_states_file)
        produce(reports_topic, report.to_json)

        get 'consumers/shinra:1:1/jobs/pending'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('This process has no pending jobs at the moment')
        expect(body).not_to include('Karafka::Pro::ActiveJob::Consumer')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when process has pending jobs' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report['jobs'][0]['status'] = 'pending'

        produce(states_topic, Fixtures.consumers_states_file)
        produce(reports_topic, report.to_json)

        get 'consumers/shinra:1:1/jobs/pending'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('Karafka::Pro::ActiveJob::Consumer')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when process has jobs reported in a transactional fashion' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report['jobs'].first['status'] = 'pending'

        produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
        produce(reports_topic, report.to_json, type: :transactional)

        get 'consumers/shinra:1:1/jobs/pending'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('Karafka::Pro::ActiveJob::Consumer')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when given process has no jobs pending' do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report['jobs'] = []

        produce(reports_topic, report.to_json)

        get 'consumers/shinra:1:1/jobs/pending'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('This process has no pending jobs at the moment')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when given process does not exist' do
      before { get 'consumers/4e8f7174ae53/jobs/pending' }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end
  end
end
