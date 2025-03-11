# frozen_string_literal: true

# We use this spec to check that pro components are not available when not in pro
RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  let(:make_better) { 'Please help us make the Karafka ecosystem better' }

  describe '#health' do
    before { get 'health' }

    it do
      expect(response).not_to be_ok
      expect(body).to include(make_better)
      expect(status).to eq(402)
    end
  end

  describe '#explorer' do
    before { get 'explorer' }

    it do
      expect(response).not_to be_ok
      expect(body).to include(make_better)
      expect(status).to eq(402)
    end
  end

  describe '#dlq' do
    before { get 'dlq' }

    it do
      expect(response).not_to be_ok
      expect(body).to include(make_better)
      expect(status).to eq(402)
    end
  end

  describe 'custom assets' do
    let(:custom_css) { "assets/#{Karafka::Web::VERSION}/stylesheets/custom.css" }
    let(:custom_js) { "assets/#{Karafka::Web::VERSION}/javascripts/custom.js" }

    let(:ui_config) { Karafka::Web.config.ui }

    after do
      ui_config.custom_css = false
      ui_config.custom_js = false
    end

    context 'when there is no custom css' do
      before { get custom_css }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when there is custom inline css' do
      let(:css_content) { 'div { display: none }' }

      before do
        ui_config.custom_css = css_content

        get custom_css
      end

      it do
        expect(response).to be_ok
        expect(status).to eq(200)
        expect(body).to eq(css_content)
        expect(headers['content-type']).to eq('text/css')
        expect(headers['cache-control']).to eq('max-age=31536000, immutable')
      end
    end

    context 'when there is custom css path that points to nothing' do
      let(:css_content) { '/nothing/really' }

      before do
        ui_config.custom_css = css_content

        get custom_css
      end

      it 'expect to treat is as a stringified content' do
        expect(response).to be_ok
        expect(status).to eq(200)
        expect(body).to eq(css_content)
        expect(headers['content-type']).to eq('text/css')
        expect(headers['cache-control']).to eq('max-age=31536000, immutable')
      end
    end

    context 'when there is custom css path that points to a file to show' do
      let(:css_content) { File.join(Karafka::Web.gem_root, 'Gemfile') }

      let(:fetched_content) { File.read(css_content) }

      before do
        ui_config.custom_css = css_content

        get custom_css
      end

      it 'expect to treat is as a stringified content' do
        expect(response).to be_ok
        expect(status).to eq(200)
        expect(body).to eq(fetched_content)
        expect(headers['content-type']).to eq('text/css')
        expect(headers['cache-control']).to eq('max-age=31536000, immutable')
      end
    end

    context 'when there is no custom js' do
      before { get custom_js }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when there is custom inline js' do
      let(:js_content) { 'div { display: none }' }

      before do
        ui_config.custom_js = js_content

        get custom_js
      end

      it do
        expect(response).to be_ok
        expect(status).to eq(200)
        expect(body).to eq(js_content)
        expect(headers['content-type']).to eq('application/javascript')
        expect(headers['cache-control']).to eq('max-age=31536000, immutable')
      end
    end

    context 'when there is custom js path that points to nothing' do
      let(:js_content) { '/nothing/really' }

      before do
        ui_config.custom_js = js_content

        get custom_js
      end

      it 'expect to treat is as a stringified content' do
        expect(response).to be_ok
        expect(status).to eq(200)
        expect(body).to eq(js_content)
        expect(headers['content-type']).to eq('application/javascript')
        expect(headers['cache-control']).to eq('max-age=31536000, immutable')
      end
    end

    context 'when there is custom js path that points to a file to show' do
      let(:js_content) { File.join(Karafka::Web.gem_root, 'Gemfile') }

      let(:fetched_content) { File.read(js_content) }

      before do
        ui_config.custom_js = js_content

        get custom_js
      end

      it 'expect to treat is as a stringified content' do
        expect(response).to be_ok
        expect(status).to eq(200)
        expect(body).to eq(fetched_content)
        expect(headers['content-type']).to eq('application/javascript')
        expect(headers['cache-control']).to eq('max-age=31536000, immutable')
      end
    end
  end
end
