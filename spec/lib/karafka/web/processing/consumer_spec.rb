# frozen_string_literal: true

RSpec.describe_current do
  subject(:consumer) { described_class.new }

  let(:messages) { [] }
  let(:coordinator) { build(:processing_coordinator) }
  let(:migrator) { instance_double(Karafka::Web::Management::Migrator) }
  let(:state_aggregator) { instance_double(Karafka::Web::Processing::Consumers::Aggregators::State) }
  let(:metrics_aggregator) { instance_double(Karafka::Web::Processing::Consumers::Aggregators::Metrics) }
  let(:schema_manager) { instance_double(Karafka::Web::Processing::Consumers::SchemaManager) }
  let(:state_contract) { instance_double(Karafka::Web::Processing::Consumers::Contracts::State) }
  let(:metrics_contract) { instance_double(Karafka::Web::Processing::Consumers::Contracts::Metrics) }

  before do
    allow(consumer).to receive_messages(
      messages: messages,
      coordinator: coordinator,
      mark_as_consumed: nil
    )

    allow(Karafka::Web::Management::Migrator).to receive(:new).and_return(migrator)
    allow(migrator).to receive(:call)

    allow(Karafka::Web::Processing::Consumers::SchemaManager).to receive(:new).and_return(schema_manager)
    allow(Karafka::Web::Processing::Consumers::Aggregators::State).to receive(:new).and_return(state_aggregator)
    allow(Karafka::Web::Processing::Consumers::Aggregators::Metrics).to receive(:new).and_return(metrics_aggregator)
    allow(Karafka::Web::Processing::Consumers::Contracts::State).to receive(:new).and_return(state_contract)
    allow(Karafka::Web::Processing::Consumers::Contracts::Metrics).to receive(:new).and_return(metrics_contract)

    allow(state_aggregator).to receive(:to_h).and_return({})
    allow(metrics_aggregator).to receive(:to_h).and_return({})
    allow(state_contract).to receive(:validate!)
    allow(metrics_contract).to receive(:validate!)
    allow(Karafka::Web::Processing::Publisher).to receive(:publish)
  end

  describe '#consume' do
    context 'when messages are empty' do
      it 'does not dispatch' do
        allow(Karafka::Web::Processing::Publisher).to receive(:publish)
        consumer.consume
        expect(Karafka::Web::Processing::Publisher).not_to have_received(:publish)
      end
    end

    context 'when consuming consumer type messages' do
      let(:message1) do
        instance_double(
          Karafka::Messages::Message,
          payload: {
            schema_version: '1.5.0',
            type: 'consumer',
            process: { id: 'process-1' },
            dispatched_at: Time.now.to_f
          },
          offset: 100
        )
      end

      let(:message2) do
        instance_double(
          Karafka::Messages::Message,
          payload: {
            schema_version: '1.5.0',
            type: 'consumer',
            process: { id: 'process-2' },
            dispatched_at: Time.now.to_f + 1
          },
          offset: 101
        )
      end

      let(:messages) { [message1, message2] }

      context 'when schema is current' do
        before do
          allow(schema_manager).to receive(:call).and_return(:current)
          allow(state_aggregator).to receive(:add)
          allow(state_aggregator).to receive(:add_state)
          allow(state_aggregator).to receive(:stats).and_return({})
          allow(metrics_aggregator).to receive(:add_report)
          allow(metrics_aggregator).to receive(:add_stats)
        end

        it 'processes messages through aggregators' do
          allow(state_aggregator).to receive(:add)
          allow(metrics_aggregator).to receive(:add_report)

          consumer.consume

          expect(state_aggregator).to have_received(:add).with(message1.payload, message1.offset)
          expect(state_aggregator).to have_received(:add).with(message2.payload, message2.offset)
          expect(metrics_aggregator).to have_received(:add_report).with(message1.payload)
          expect(metrics_aggregator).to have_received(:add_report).with(message2.payload)
        end

        it 'marks last message as consumed on periodic flush' do
          allow(consumer).to receive(:periodic_flush?).and_return(true)
          allow(consumer).to receive(:mark_as_consumed)

          consumer.consume

          expect(consumer).to have_received(:mark_as_consumed).with(message2)
        end
      end

      context 'when schema is newer' do
        before do
          allow(schema_manager).to receive(:call).and_return(:newer)
          allow(schema_manager).to receive(:invalidate!)
        end

        it 'raises incompatible schema error' do
          expect { consumer.consume }.to raise_error(
            Karafka::Web::Errors::Processing::IncompatibleSchemaError
          )
        end

        it 'invalidates schema manager' do
          allow(schema_manager).to receive(:invalidate!)

          begin
            consumer.consume
          rescue Karafka::Web::Errors::Processing::IncompatibleSchemaError
            # Expected
          end

          expect(schema_manager).to have_received(:invalidate!)
        end
      end

      context 'when schema is older' do
        before do
          allow(schema_manager).to receive(:call).and_return(:older)
          allow(state_aggregator).to receive(:add_state)
        end

        it 'only tracks state without full processing' do
          allow(state_aggregator).to receive(:add_state)
          allow(state_aggregator).to receive(:add)
          allow(metrics_aggregator).to receive(:add_report)

          consumer.consume

          expect(state_aggregator).to have_received(:add_state).with(message1.payload, message1.offset)
          expect(state_aggregator).to have_received(:add_state).with(message2.payload, message2.offset)
          expect(state_aggregator).not_to have_received(:add)
          expect(metrics_aggregator).not_to have_received(:add_report)
        end

        context 'with old schema 1.2.x report using process[:name] instead of process[:id]' do
          let(:old_schema_message) do
            instance_double(
              Karafka::Messages::Message,
              payload: {
                schema_version: '1.2.9',
                type: 'consumer',
                process: {
                  name: 'old-process:1:1', # Old schema used :name
                  status: 'running',
                  started_at: Time.now.to_f
                },
                dispatched_at: Time.now.to_f,
                stats: { busy: 0, enqueued: 0 }
              },
              offset: 200
            )
          end

          let(:messages) { [old_schema_message] }

          it 'migrates the report and processes it without crashing' do
            allow(state_aggregator).to receive(:add_state)

            expect { consumer.consume }.not_to raise_error
          end

          it 'migrates process[:name] to process[:id] before passing to aggregator' do
            allow(state_aggregator).to receive(:add_state)

            consumer.consume

            # Verify the migrated report was passed to add_state
            expect(state_aggregator).to have_received(:add_state) do |report, offset|
              expect(report[:process][:id]).to eq('old-process:1:1')
              expect(report[:process]).not_to have_key(:name)
              expect(offset).to eq(200)
            end
          end

          it 'fixes the exact issue from #851 where to_sym was called on nil' do
            # This test ensures that the crash described in issue #851 is fixed:
            # "undefined method 'to_sym' for nil" when processing old reports
            # The migration system should prevent this by renaming :name to :id
            allow(state_aggregator).to receive(:add_state) do |report, _offset|
              # This would have crashed in v0.11.3 without the migration
              # because report[:process][:id] would be nil
              expect(report[:process][:id]).not_to be_nil
              expect { report[:process][:id].to_sym }.not_to raise_error
            end

            consumer.consume

            expect(state_aggregator).to have_received(:add_state)
          end
        end
      end
    end

    context 'when consuming non-consumer type messages' do
      let(:producer_message) do
        instance_double(
          Karafka::Messages::Message,
          payload: { type: 'producer', process: { id: 'producer-1' } },
          offset: 100
        )
      end

      let(:messages) { [producer_message] }

      it 'filters out non-consumer messages' do
        allow(schema_manager).to receive(:call).and_return(:current)

        allow(state_aggregator).to receive(:add)
        allow(metrics_aggregator).to receive(:add_report)

        consumer.consume

        expect(state_aggregator).not_to have_received(:add)
        expect(metrics_aggregator).not_to have_received(:add_report)
      end
    end

    context 'when handling periodic flush' do
      let(:message) do
        instance_double(
          Karafka::Messages::Message,
          payload: {
            type: 'consumer',
            process: { id: 'process-1' },
            dispatched_at: Time.now.to_f
          },
          offset: 100
        )
      end

      let(:messages) { [message] }

      before do
        allow(schema_manager).to receive(:call).and_return(:current)
        allow(state_aggregator).to receive(:add)
        allow(state_aggregator).to receive(:stats).and_return({})
        allow(metrics_aggregator).to receive(:add_report)
        allow(metrics_aggregator).to receive(:add_stats)
      end

      it 'does not flush when interval has not passed' do
        allow(consumer).to receive(:periodic_flush?).and_return(false)
        allow(Karafka::Web::Processing::Publisher).to receive(:publish)

        consumer.consume

        expect(Karafka::Web::Processing::Publisher).not_to have_received(:publish)
      end

      it 'flushes when interval has passed' do
        allow(consumer).to receive(:periodic_flush?).and_return(true)
        allow(Karafka::Web::Processing::Publisher).to receive(:publish)

        consumer.consume

        expect(Karafka::Web::Processing::Publisher).to have_received(:publish)
      end
    end
  end

  describe '#shutdown' do
    context 'when data has been established' do
      let(:message) do
        instance_double(
          Karafka::Messages::Message,
          payload: {
            type: 'consumer',
            process: { id: 'process-1' },
            dispatched_at: Time.now.to_f
          },
          offset: 100
        )
      end

      let(:messages) { [message] }

      before do
        allow(schema_manager).to receive(:call).and_return(:current)
        allow(state_aggregator).to receive(:add)
        allow(state_aggregator).to receive(:stats).and_return({})
        allow(metrics_aggregator).to receive(:add_report)
        allow(metrics_aggregator).to receive(:add_stats)
        allow(consumer).to receive(:periodic_flush?).and_return(false)

        # Process a message to establish data
        consumer.consume
      end

      it 'dispatches final state' do
        allow(Karafka::Web::Processing::Publisher).to receive(:publish)

        consumer.shutdown

        expect(Karafka::Web::Processing::Publisher).to have_received(:publish)
      end
    end

    context 'when no data has been established' do
      it 'does not dispatch' do
        allow(Karafka::Web::Processing::Publisher).to receive(:publish)

        consumer.shutdown

        expect(Karafka::Web::Processing::Publisher).not_to have_received(:publish)
      end
    end
  end

  describe 'bootstrap process' do
    let(:message) do
      instance_double(
        Karafka::Messages::Message,
        payload: { type: 'consumer', process: { id: 'process-1' }, dispatched_at: Time.now.to_f },
        offset: 100
      )
    end

    let(:messages) { [message] }

    it 'runs migrator on first consume' do
      allow(schema_manager).to receive(:call).and_return(:current)
      allow(state_aggregator).to receive(:add)
      allow(state_aggregator).to receive(:stats).and_return({})
      allow(metrics_aggregator).to receive(:add_report)
      allow(metrics_aggregator).to receive(:add_stats)
      allow(migrator).to receive(:call)

      consumer.consume

      expect(migrator).to have_received(:call).once
    end

    it 'does not run migrator on subsequent consumes' do
      allow(schema_manager).to receive(:call).and_return(:current)
      allow(state_aggregator).to receive(:add)
      allow(state_aggregator).to receive(:stats).and_return({})
      allow(metrics_aggregator).to receive(:add_report)
      allow(metrics_aggregator).to receive(:add_stats)
      allow(migrator).to receive(:call)

      consumer.consume
      consumer.consume

      expect(migrator).to have_received(:call).once
    end

    it 'initializes aggregators and contracts' do
      allow(schema_manager).to receive(:call).and_return(:current)
      allow(state_aggregator).to receive(:add)
      allow(state_aggregator).to receive(:stats).and_return({})
      allow(metrics_aggregator).to receive(:add_report)
      allow(metrics_aggregator).to receive(:add_stats)
      allow(Karafka::Web::Processing::Consumers::SchemaManager)
        .to receive(:new).and_return(schema_manager)
      allow(Karafka::Web::Processing::Consumers::Aggregators::State)
        .to receive(:new).and_return(state_aggregator)
      allow(Karafka::Web::Processing::Consumers::Aggregators::Metrics)
        .to receive(:new).and_return(metrics_aggregator)
      allow(Karafka::Web::Processing::Consumers::Contracts::State)
        .to receive(:new).and_return(state_contract)
      allow(Karafka::Web::Processing::Consumers::Contracts::Metrics)
        .to receive(:new).and_return(metrics_contract)

      consumer.consume

      expect(Karafka::Web::Processing::Consumers::SchemaManager)
        .to have_received(:new).once
      expect(Karafka::Web::Processing::Consumers::Aggregators::State)
        .to have_received(:new).once
      expect(Karafka::Web::Processing::Consumers::Aggregators::Metrics)
        .to have_received(:new).once
      expect(Karafka::Web::Processing::Consumers::Contracts::State)
        .to have_received(:new).once
      expect(Karafka::Web::Processing::Consumers::Contracts::Metrics)
        .to have_received(:new).once
    end
  end

  describe 'validation' do
    let(:message) do
      instance_double(
        Karafka::Messages::Message,
        payload: { type: 'consumer', process: { id: 'process-1' }, dispatched_at: Time.now.to_f },
        offset: 100
      )
    end

    let(:messages) { [message] }

    before do
      allow(schema_manager).to receive(:call).and_return(:current)
      allow(state_aggregator).to receive(:add)
      allow(state_aggregator).to receive(:stats).and_return({})
      allow(metrics_aggregator).to receive(:add_report)
      allow(metrics_aggregator).to receive(:add_stats)
      allow(consumer).to receive(:periodic_flush?).and_return(true)
    end

    it 'validates state before publishing' do
      allow(state_contract).to receive(:validate!)

      consumer.consume

      expect(state_contract).to have_received(:validate!).with(hash_including)
    end

    it 'validates metrics before publishing' do
      allow(metrics_contract).to receive(:validate!)

      consumer.consume

      expect(metrics_contract).to have_received(:validate!).with(hash_including)
    end

    context 'when validation fails' do
      before do
        allow(state_contract).to receive(:validate!).and_raise(
          Karafka::Web::Errors::ContractError, 'Invalid state'
        )
      end

      it 'propagates the validation error' do
        expect { consumer.consume }.to raise_error(
          Karafka::Web::Errors::ContractError,
          'Invalid state'
        )
      end
    end
  end
end
