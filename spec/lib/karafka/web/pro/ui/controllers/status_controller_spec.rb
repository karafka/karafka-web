# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  describe '#show' do
    context 'when all that is needed is there' do
      before { get 'status' }

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
      end
    end

    context 'when topics are missing' do
      before do
        topics_config.consumers.states.name = generate_topic_name
        topics_config.consumers.metrics.name = generate_topic_name
        topics_config.consumers.reports.name = generate_topic_name
        topics_config.errors.name = generate_topic_name

        get 'status'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
      end
    end
  end
end
