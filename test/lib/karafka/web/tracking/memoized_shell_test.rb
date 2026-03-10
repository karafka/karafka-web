# frozen_string_literal: true

describe_current do
  let(:shell) { described_class.new }

  context "when everything is as expected" do
    it { refute_empty(shell.call("hostname")) }
  end

  context "when we stored the value and next request errors" do
    let(:first_run) { shell.call("cat /dev/urandom | head -n 1") }

    before do
      first_run
      invalid = Open3.capture2("ls -nonexisting")
      Open3.stubs(:capture2).returns(invalid)
    end

    it { assert_equal(first_run, shell.call("cat /dev/urandom | head -n 1")) }
  end
end
