# frozen_string_literal: true

describe_current do
  let(:sampler) { described_class.new }

  it { assert(sampler.ruby_version.start_with?("ruby ")) }
  it { assert_includes(sampler.karafka_version, "2.5.") }
  it { assert_includes(sampler.karafka_web_version, "0.11.") }
  it { assert_includes(sampler.karafka_core_version, "2.5.") }
  it { assert(sampler.rdkafka_version.start_with?("0.2")) }
  it { assert(sampler.librdkafka_version.start_with?("2.12")) }
  it { assert(sampler.waterdrop_version.start_with?("2.8")) }
  it { refute_empty(sampler.process_id) }
end
