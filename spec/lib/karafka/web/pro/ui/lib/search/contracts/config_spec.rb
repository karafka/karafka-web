# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:matcher) { Karafka::Web::Pro::Ui::Lib::Search::Matchers::RawHeaderIncludes }

  let(:params) do
    {
      ui: {
        search: {
          matchers: [matcher]
        }
      }
    }
  end

  context 'when all values are valid' do
    it 'is valid' do
      expect(contract.call(params)).to be_success
    end
  end

  context 'when matchers is not an array' do
    before { params[:ui][:search][:matchers] = 'not_an_array' }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when matchers is an empty array' do
    before { params[:ui][:search][:matchers] = [] }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when a matcher does not respond to name' do
    let(:invalid_matcher) do
      Class.new do
        def call
          raise
        end
      end
    end

    before { params[:ui][:search][:matchers] = [invalid_matcher] }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when a matcher does not respond to call' do
    let(:invalid_matcher) do
      Class.new do
        def self.name
          'ExampleMatcher'
        end
      end
    end

    before { params[:ui][:search][:matchers] = [invalid_matcher] }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when matchers have duplicate names' do
    let(:duplicate_matcher) do
      Class.new do
        def self.name
          'ExampleMatcher'
        end

        def self.call
          # some implementation
        end
      end
    end

    before { params[:ui][:search][:matchers] = [matcher, duplicate_matcher] }

    it { expect(contract.call(params)).not_to be_success }
  end
end
