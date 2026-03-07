# frozen_string_literal: true

describe_current do
  let(:contract) { described_class.new }

  let(:config) do
    {
      id: 0,
      lag_stored: 0,
      lag_stored_d: 0,
      lag: 2,
      lag_d: -1,
      committed_offset: 0,
      committed_offset_fd: 0,
      stored_offset: 0,
      stored_offset_fd: 0,
      fetch_state: "active",
      poll_state: "active",
      poll_state_ch: 0,
      hi_offset: 1,
      hi_offset_fd: 0,
      lo_offset: 0,
      eof_offset: 0,
      ls_offset: 0,
      ls_offset_d: 0,
      ls_offset_fd: 0,
      transactional: false
    }
  end

  context "when config is valid" do
    it { assert(contract.call(config).success?) }
  end

  context "when id is less than 0" do
    before { config[:id] = -1 }

    it { refute(contract.call(config).success?) }
  end

  %i[
    fetch_state
    poll_state
  ].each do |state|
    context "when #{state} is not present" do
      before { config.delete(state) }

      it { refute(contract.call(config).success?) }
    end

    context "when #{state} is not a string" do
      before { config[state] = rand }

      it { refute(contract.call(config).success?) }
    end

    context "when #{state} is empty" do
      before { config[state] = "" }

      it { refute(contract.call(config).success?) }
    end
  end

  %i[
    id
    lag_stored
    lag_stored_d
    lag
    lag_d
    committed_offset
    committed_offset_fd
    stored_offset
    stored_offset_fd
    hi_offset
    hi_offset_fd
    lo_offset
    eof_offset
    ls_offset
    ls_offset_d
    ls_offset_fd
    poll_state_ch
    transactional
  ].each do |key|
    context "when #{key} is not numeric" do
      before { config[key] = "2" }

      it { refute(contract.call(config).success?) }
    end

    context "when #{key} is missing" do
      before { config.delete(key) }

      it { refute(contract.call(config).success?) }
    end
  end

  %i[
    committed_offset_fd
    stored_offset_fd
    ls_offset_fd
    hi_offset_fd
    poll_state_ch
  ].each do |fd|
    context "when #{fd} is less than 0" do
      before { config[fd] = -1 }

      it { refute(contract.call(config).success?) }
    end
  end
end
