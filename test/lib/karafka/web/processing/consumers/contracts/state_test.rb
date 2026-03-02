# frozen_string_literal: true

describe_current do
  let(:contract) { described_class.new }

  let(:params) do
    {
      schema_version: "1.0.0",
      dispatched_at: Time.now.to_f,
      schema_state: "compatible",
      stats: {
        batches: 10,
        messages: 100,
        jobs: 11,
        retries: 5,
        dead: 2,
        errors: 3,
        busy: 4,
        enqueued: 6,
        workers: 5,
        processes: 2,
        rss: 512.45,
        listeners: {
          active: 3,
          standby: 0
        },
        utilization: 70.2,
        lag_hybrid: 50,
        lag: 10
      },
      processes: {}
    }
  end

  context "when all values are valid" do
    it "is valid" do
      assert_predicate(contract.call(params), :success?)
    end
  end

  context "when validating schema_version" do
    context "when schema_version is missing" do
      before { params.delete(:schema_version) }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when schema_version is empty" do
      before { params[:schema_version] = "" }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when schema_version is not a string" do
      before { params[:schema_version] = 123 }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when schema_version is nil" do
      before { params[:schema_version] = nil }

      it { refute_predicate(contract.call(params), :success?) }
    end
  end

  context "when validating dispatched_at" do
    context "when dispatched_at is missing" do
      before { params.delete(:dispatched_at) }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when dispatched_at is negative" do
      before { params[:dispatched_at] = -1 }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when dispatched_at is zero" do
      before { params[:dispatched_at] = 0 }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when dispatched_at is not a number" do
      before { params[:dispatched_at] = "test" }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when dispatched_at is nil" do
      before { params[:dispatched_at] = nil }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when dispatched_at is a valid float" do
      before { params[:dispatched_at] = 1_234_567_890.123 }

      it { assert_predicate(contract.call(params), :success?) }
    end

    context "when dispatched_at is a valid integer" do
      before { params[:dispatched_at] = 1_234_567_890 }

      it { assert_predicate(contract.call(params), :success?) }
    end
  end

  context "when validating stats" do
    context "when stats is missing" do
      before { params.delete(:stats) }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when stats is not a hash" do
      before { params[:stats] = "not a hash" }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when stats is nil" do
      before { params[:stats] = nil }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when stats is an array" do
      before { params[:stats] = [] }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when stats has invalid aggregated stats" do
      before { params[:stats][:batches] = "not a number" }

      it { assert_raises(Karafka::Web::Errors::ContractError) { contract.call(params) } }
    end

    context "when stats is missing required fields" do
      before { params[:stats].delete(:batches) }

      it { assert_raises(Karafka::Web::Errors::ContractError) { contract.call(params) } }
    end
  end

  context "when validating processes" do
    context "when processes is missing" do
      before { params.delete(:processes) }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when processes is not a hash" do
      before { params[:processes] = [] }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when processes is nil" do
      before { params[:processes] = nil }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when process has invalid structure" do
      before { params[:processes] = { test: {} } }

      it { assert_raises(Karafka::Web::Errors::ContractError) { contract.call(params) } }
    end

    context "when process has valid structure" do
      before do
        params[:processes] = {
          test_process: {
            dispatched_at: Time.now.to_f,
            offset: 100
          }
        }
      end

      it { assert_predicate(contract.call(params), :success?) }
    end

    context "when process ID is a string instead of symbol" do
      before do
        params[:processes] = {
          "string_process_id" => {
            dispatched_at: Time.now.to_f,
            offset: 100
          }
        }
      end

      it { refute_predicate(contract.call(params), :success?) }

      it "includes appropriate error message" do
        result = contract.call(params)
        assert_includes(result.errors[:processes], "must be a hash with symbol keys")
      end
    end

    context "when multiple process IDs are strings" do
      before do
        params[:processes] = {
          "process_1" => {
            dispatched_at: Time.now.to_f,
            offset: 100
          },
          "process_2" => {
            dispatched_at: Time.now.to_f,
            offset: 200
          }
        }
      end

      it { refute_predicate(contract.call(params), :success?) }

      it "includes appropriate error message" do
        result = contract.call(params)
        assert_includes(result.errors[:processes], "must be a hash with symbol keys")
      end
    end

    context "when mixing string and symbol process IDs" do
      before do
        params[:processes] = {
          :valid_process => {
            dispatched_at: Time.now.to_f,
            offset: 100
          },
          "invalid_process" => {
            dispatched_at: Time.now.to_f,
            offset: 200
          }
        }
      end

      it { refute_predicate(contract.call(params), :success?) }

      it "includes appropriate error message" do
        result = contract.call(params)
        assert_includes(result.errors[:processes], "must be a hash with symbol keys")
      end
    end

    context "when process IDs are symbols" do
      before do
        params[:processes] = {
          process_1: {
            dispatched_at: Time.now.to_f,
            offset: 100
          },
          process_2: {
            dispatched_at: Time.now.to_f,
            offset: 200
          }
        }
      end

      it { assert_predicate(contract.call(params), :success?) }
    end
  end

  context "when validating schema_state" do
    context "when schema_state is missing" do
      before { params.delete(:schema_state) }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when schema_state is compatible" do
      before { params[:schema_state] = "compatible" }

      it { assert_predicate(contract.call(params), :success?) }
    end

    context "when schema_state is incompatible" do
      before { params[:schema_state] = "incompatible" }

      it { assert_predicate(contract.call(params), :success?) }
    end

    context "when schema_state is not one of the accepted values" do
      before { params[:schema_state] = "na" }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when schema_state is nil" do
      before { params[:schema_state] = nil }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when schema_state is empty string" do
      before { params[:schema_state] = "" }

      it { refute_predicate(contract.call(params), :success?) }
    end

    context "when schema_state is not a string" do
      before { params[:schema_state] = 123 }

      it { refute_predicate(contract.call(params), :success?) }
    end
  end

  context "when validating complete state with multiple processes" do
    before do
      params[:processes] = {
        worker_1: {
          dispatched_at: Time.now.to_f - 10,
          offset: 100
        },
        worker_2: {
          dispatched_at: Time.now.to_f - 5,
          offset: 200
        },
        worker_3: {
          dispatched_at: Time.now.to_f,
          offset: 300
        }
      }
    end

    it { assert_predicate(contract.call(params), :success?) }
  end
end
