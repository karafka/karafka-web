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

  let(:ui_config) { Karafka::Web.config.ui }

  describe 'custom nav' do
    before do
      ui_config.custom.nav_erb = nav_erb

      get 'dashboard'
    end

    after { ui_config.custom.nav_erb = false }

    context 'when nav_erb is set to an erb template code' do
      let(:nav_erb) do
        <<~ERB
          <strong><%= 100 %></strong>
        ERB
      end

      it 'expect to render it' do
        expect(response).to be_ok
        expect(body).to include('<strong>100</strong>')
      end
    end

    context 'when it is set to a non-existing file' do
      let(:nav_erb) { '/tmp/does-not-exist' }

      it 'expect to render it as an erb string' do
        expect(response).to be_ok
        expect(body).to include('/tmp/does-not-exist')
      end
    end

    context 'when it is set to an existing custom user erb component' do
      let(:nav_erb) { Fixtures.path('custom/nav.erb') }

      it 'expect to render it' do
        expect(response).to be_ok
        expect(body).to include('this is a test')
      end
    end
  end
end
