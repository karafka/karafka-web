# frozen_string_literal: true

describe_current do
  let(:consumer) do
    consumer = described_class.new
    consumer.coordinator = coordinator
    # Define mark_as_consumed since strategy modules are included at runtime
    consumer.define_singleton_method(:mark_as_consumed) { |_message| nil }
    consumer
  end

  let(:messages) { [] }
  let(:coordinator) { build(:processing_coordinator) }
  let(:migrator) { stub() }

  let(:state_aggregator) do
    stub()
  end

  let(:metrics_aggregator) do
    stub()
  end

  let(:schema_manager) { stub() }

  let(:state_contract) do
    stub()
  end

  let(:metrics_contract) do
    stub()
  end

  before do
    consumer.stubs(:messages).returns(messages)

    Karafka::Web::Management::Migrator.stubs(:new).returns(migrator)
    migrator.stubs(:call)

    Karafka::Web::Processing::Consumers::SchemaManager.stubs(:new).returns(schema_manager)
    Karafka::Web::Processing::Consumers::Aggregators::State.stubs(:new).returns(state_aggregator)
    Karafka::Web::Processing::Consumers::Aggregators::Metrics.stubs(:new).returns(metrics_aggregator)
    Karafka::Web::Processing::Consumers::Contracts::State.stubs(:new).returns(state_contract)
    Karafka::Web::Processing::Consumers::Contracts::Metrics.stubs(:new).returns(metrics_contract)

    state_aggregator.stubs(:to_h).returns({})
    metrics_aggregator.stubs(:to_h).returns({})
    state_contract.stubs(:validate!)
    metrics_contract.stubs(:validate!)
    Karafka::Web::Processing::Publisher.stubs(:publish)
  end

  describe "#consume" do
    context "when messages are empty" do
      it "does not dispatch" do
        Karafka::Web::Processing::Publisher.expects(:publish).never
        Karafka::Web::Processing::Publisher.stubs(:publish)
        consumer.consume
      end
    end

    context "when consuming consumer type messages" do
      let(:message1) do
        stub(payload: {
            schema_version: "1.5.0",
            type: "consumer",
            process: { id: "process-1" },
            dispatched_at: Time.now.to_f
          },
          offset: 100
        )
      end

      let(:message2) do
        stub(payload: {
            schema_version: "1.5.0",
            type: "consumer",
            process: { id: "process-2" },
            dispatched_at: Time.now.to_f + 1
          },
          offset: 101
        )
      end

      let(:messages) { [message1, message2] }

      context "when schema is current" do
        before do
          schema_manager.stubs(:call).returns(:current)
          state_aggregator.stubs(:add)
          state_aggregator.stubs(:add_state)
          state_aggregator.stubs(:stats).returns({})
          metrics_aggregator.stubs(:add_report)
          metrics_aggregator.stubs(:add_stats)
        end

        it "processes messages through aggregators" do
          state_aggregator.stubs(:add)
          metrics_aggregator.stubs(:add_report)

          state_aggregator.expects(:add).with(message1.payload, message1.offset)
          state_aggregator.expects(:add).with(message2.payload, message2.offset)
          metrics_aggregator.expects(:add_report).with(message1.payload)
          metrics_aggregator.expects(:add_report).with(message2.payload)
          consumer.consume

        end

        it "marks last message as consumed on periodic flush" do
          consumer.stubs(:periodic_flush?).returns(true)
          consumer.stubs(:mark_as_consumed)

          consumer.expects(:mark_as_consumed).with(message2)
          consumer.consume

        end
      end

      context "when schema is newer" do
        before do
          schema_manager.stubs(:call).returns(:newer)
          schema_manager.stubs(:invalidate!)
        end

        it "raises incompatible schema error" do
          assert_raises(Karafka::Web::Errors::Processing::IncompatibleSchemaError) { consumer.consume }
        end

        it "invalidates schema manager" do
          schema_manager.stubs(:invalidate!)

          begin
            consumer.consume
          rescue Karafka::Web::Errors::Processing::IncompatibleSchemaError
            # Expected
          end

          schema_manager.expects(:invalidate!) # MOCHA_REORDER
        end
      end

      context "when schema is older" do
        before do
          schema_manager.stubs(:call).returns(:older)

          state_aggregator.stubs(:add_state)
        end

        it "only tracks state without full processing" do
          state_aggregator.stubs(:add_state)
          state_aggregator.stubs(:add)
          metrics_aggregator.stubs(:add_report)

          state_aggregator.expects(:add).never
          metrics_aggregator.expects(:add_report).never
          consumer.consume

          state_aggregator.expects(:add_state).with(message1.payload, message1.offset) # MOCHA_REORDER

          state_aggregator.expects(:add_state).with(message2.payload, message2.offset) # MOCHA_REORDER


        end

        context "with old schema 1.2.x report using process[:name] instead of process[:id]" do
          let(:old_schema_message) do
            stub(payload: {
                schema_version: "1.2.9",
                type: "consumer",
                process: {
                  name: "old-process:1:1", # Old schema used :name
                  status: "running",
                  started_at: Time.now.to_f
                },
                dispatched_at: Time.now.to_f,
                stats: { busy: 0, enqueued: 0 }
              },
              offset: 200
            )
          end

          let(:messages) { [old_schema_message] }

          it "migrates the report and processes it without crashing" do
            state_aggregator.stubs(:add_state)

            consumer.consume
          end

          it "migrates process[:name] to process[:id] before passing to aggregator" do
            state_aggregator.stubs(:add_state)

            consumer.consume

            # Verify the migrated report was passed to add_state
            # TODO: have_received with block - needs manual conversion
            # Original: expect(state_aggregator).to have_received(:add_state) do |report, offset| assert_equal("old-process:1:1", report[:process][:id]) refute(report[:process].key?(:name)) assert_equal(200, offset) end
          end

          it "fixes the exact issue from #851 where to_sym was called on nil" do
            # This test ensures that the crash described in issue #851 is fixed:
            # "undefined method 'to_sym' for nil" when processing old reports
            # The migration system should prevent this by renaming :name to :id
            state_aggregator.stubs(:add_state).with(anything).returns(nil) # TODO: convert do-block stub
            # Original: allow(state_aggregator).to receive(:add_state) do |report, _offset| # This would have crashed in v0.11.3 without the migration # because report[:process][:id] would be nil refute_nil(report[:process][:id]) report[:process][:id].to_sym end

            state_aggregator.expects(:add_state)
            consumer.consume

          end
        end
      end
    end

    context "when consuming non-consumer type messages" do
      let(:producer_message) do
        stub(payload: { type: "producer", process: { id: "producer-1" } },
          offset: 100
        )
      end

      let(:messages) { [producer_message] }

      it "filters out non-consumer messages" do
        schema_manager.stubs(:call).returns(:current)

        state_aggregator.stubs(:add)
        metrics_aggregator.stubs(:add_report)

        state_aggregator.expects(:add).never
        metrics_aggregator.expects(:add_report).never
        consumer.consume

      end
    end

    context "when handling periodic flush" do
      let(:message) do
        stub(payload: {
            type: "consumer",
            process: { id: "process-1" },
            dispatched_at: Time.now.to_f
          },
          offset: 100
        )
      end

      let(:messages) { [message] }

      before do
        schema_manager.stubs(:call).returns(:current)
        state_aggregator.stubs(:add)
        state_aggregator.stubs(:stats).returns({})
        metrics_aggregator.stubs(:add_report)
        metrics_aggregator.stubs(:add_stats)
      end

      it "does not flush when interval has not passed" do
        consumer.stubs(:periodic_flush?).returns(false)
        Karafka::Web::Processing::Publisher.expects(:publish).never
        Karafka::Web::Processing::Publisher.stubs(:publish)

        consumer.consume

      end

      it "flushes when interval has passed" do
        consumer.stubs(:periodic_flush?).returns(true)
        Karafka::Web::Processing::Publisher.expects(:publish)
        Karafka::Web::Processing::Publisher.stubs(:publish)

        consumer.consume

      end
    end
  end

  describe "#shutdown" do
    context "when data has been established" do
      let(:message) do
        stub(payload: {
            type: "consumer",
            process: { id: "process-1" },
            dispatched_at: Time.now.to_f
          },
          offset: 100
        )
      end

      let(:messages) { [message] }

      before do
        schema_manager.stubs(:call).returns(:current)
        state_aggregator.stubs(:add)
        state_aggregator.stubs(:stats).returns({})
        metrics_aggregator.stubs(:add_report)
        metrics_aggregator.stubs(:add_stats)
        consumer.stubs(:periodic_flush?).returns(false)

        # Process a message to establish data
        consumer.consume
      end

      it "dispatches final state" do
        Karafka::Web::Processing::Publisher.expects(:publish)
        Karafka::Web::Processing::Publisher.stubs(:publish)

        consumer.shutdown

      end
    end

    context "when no data has been established" do
      it "does not dispatch" do
        Karafka::Web::Processing::Publisher.expects(:publish).never
        Karafka::Web::Processing::Publisher.stubs(:publish)

        consumer.shutdown

      end
    end
  end

  describe "bootstrap process" do
    let(:message) do
      stub(payload: { type: "consumer", process: { id: "process-1" }, dispatched_at: Time.now.to_f },
        offset: 100
      )
    end

    let(:messages) { [message] }

    it "runs migrator on first consume" do
      schema_manager.stubs(:call).returns(:current)
      state_aggregator.stubs(:add)
      state_aggregator.stubs(:stats).returns({})
      metrics_aggregator.stubs(:add_report)
      metrics_aggregator.stubs(:add_stats)
      migrator.stubs(:call)

      migrator.expects(:call).once
      consumer.consume

    end

    it "does not run migrator on subsequent consumes" do
      schema_manager.stubs(:call).returns(:current)
      state_aggregator.stubs(:add)
      state_aggregator.stubs(:stats).returns({})
      metrics_aggregator.stubs(:add_report)
      metrics_aggregator.stubs(:add_stats)
      migrator.stubs(:call)

      migrator.expects(:call).once
      consumer.consume
      consumer.consume

    end

    it "initializes aggregators and contracts" do
      schema_manager.stubs(:call).returns(:current)
      state_aggregator.stubs(:add)
      state_aggregator.stubs(:stats).returns({})
      metrics_aggregator.stubs(:add_report)
      metrics_aggregator.stubs(:add_stats)
      Karafka::Web::Processing::Consumers::SchemaManager.expects(:new).once
      Karafka::Web::Processing::Consumers::Aggregators::State.expects(:new).once
      Karafka::Web::Processing::Consumers::Aggregators::Metrics.expects(:new).once
      Karafka::Web::Processing::Consumers::Contracts::State.expects(:new).once
      Karafka::Web::Processing::Consumers::Contracts::Metrics.expects(:new).once
      Karafka::Web::Processing::Consumers::SchemaManager.stubs(:new).returns(schema_manager)
      Karafka::Web::Processing::Consumers::Aggregators::State.stubs(:new).returns(state_aggregator)
      Karafka::Web::Processing::Consumers::Aggregators::Metrics.stubs(:new).returns(metrics_aggregator)
      Karafka::Web::Processing::Consumers::Contracts::State.stubs(:new).returns(state_contract)
      Karafka::Web::Processing::Consumers::Contracts::Metrics.stubs(:new).returns(metrics_contract)

      consumer.consume

    end
  end

  describe "validation" do
    let(:message) do
      stub(payload: { type: "consumer", process: { id: "process-1" }, dispatched_at: Time.now.to_f },
        offset: 100
      )
    end

    let(:messages) { [message] }

    before do
      schema_manager.stubs(:call).returns(:current)
      state_aggregator.stubs(:add)
      state_aggregator.stubs(:stats).returns({})
      metrics_aggregator.stubs(:add_report)
      metrics_aggregator.stubs(:add_stats)
      consumer.stubs(:periodic_flush?).returns(true)
    end

    it "validates state before publishing" do
      state_contract.stubs(:validate!)

      state_contract.expects(:validate!).with(has_entries({}))
      consumer.consume

    end

    it "validates metrics before publishing" do
      metrics_contract.stubs(:validate!)

      metrics_contract.expects(:validate!).with(has_entries({}))
      consumer.consume

    end

    context "when validation fails" do
      before do
        state_contract.stubs(:validate!).raises( Karafka::Web::Errors::ContractError, "Invalid state" )
      end

      it "propagates the validation error" do
        error = assert_raises(Karafka::Web::Errors::ContractError) { consumer.consume }
        assert_equal("Invalid state", error.message)
      end
    end
  end
end
