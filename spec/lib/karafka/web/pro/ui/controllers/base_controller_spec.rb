# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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
