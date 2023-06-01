# frozen_string_literal: true

RSpec.describe_current do
  subject(:shell) { described_class.new }

  context 'when everything is as expected' do
    it { expect(shell.call('hostname')).not_to be_empty }
  end

  context 'when we stored the value and next request errors' do
    let(:first_run) { shell.call('cat /dev/urandom | head -n 1') }

    before do
      first_run
      invalid = Open3.capture2('ls -nonexisting')
      allow(Open3).to receive(:capture2).and_return(invalid)
    end

    it { expect(shell.call('cat /dev/urandom | head -n 1')).to eq(first_run) }
  end
end
