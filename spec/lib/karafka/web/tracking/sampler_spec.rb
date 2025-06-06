# frozen_string_literal: true

RSpec.describe_current do
  subject(:sampler) { described_class.new }

  it { expect(sampler.ruby_version).to start_with('ruby ') }
  it { expect(sampler.karafka_version).to include('2.5.') }
  it { expect(sampler.karafka_web_version).to include('0.11.') }
  it { expect(sampler.karafka_core_version).to include('2.5.') }
  it { expect(sampler.rdkafka_version).to start_with('0.1') }
  it { expect(sampler.librdkafka_version).to start_with('2.8') }
  it { expect(sampler.waterdrop_version).to start_with('2.8') }
  it { expect(sampler.process_id).not_to be_empty }
end
