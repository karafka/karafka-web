# frozen_string_literal: true

RSpec.describe_current do
  subject(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe 'DSL configuration' do
    it { expect(described_class.independent?).to be(false) }
    it { expect(described_class.dependency).to eq(:consumers_reports) }
    it { expect(described_class.halted_details).to eq({ incompatible: [] }) }
  end

  describe '#call' do
    context 'when all processes have compatible schemas' do
      let(:process1) { instance_double(Karafka::Web::Ui::Models::Process, schema_compatible?: true) }
      let(:process2) { instance_double(Karafka::Web::Ui::Models::Process, schema_compatible?: true) }

      before do
        context.processes = [process1, process2]
      end

      it 'returns success' do
        result = check.call

        expect(result.status).to eq(:success)
        expect(result.details[:incompatible]).to be_empty
      end
    end

    context 'when some processes have incompatible schemas' do
      let(:compatible_process) do
        instance_double(Karafka::Web::Ui::Models::Process, schema_compatible?: true)
      end

      let(:incompatible_process) do
        instance_double(Karafka::Web::Ui::Models::Process, schema_compatible?: false)
      end

      before do
        context.processes = [compatible_process, incompatible_process]
      end

      it 'returns warning' do
        result = check.call

        expect(result.status).to eq(:warning)
        expect(result.success?).to be(true)
      end

      it 'includes incompatible processes in details' do
        result = check.call

        expect(result.details[:incompatible]).to contain_exactly(incompatible_process)
      end
    end

    context 'when all processes have incompatible schemas' do
      let(:incompatible1) do
        instance_double(Karafka::Web::Ui::Models::Process, schema_compatible?: false)
      end

      let(:incompatible2) do
        instance_double(Karafka::Web::Ui::Models::Process, schema_compatible?: false)
      end

      before do
        context.processes = [incompatible1, incompatible2]
      end

      it 'returns warning with all incompatible processes' do
        result = check.call

        expect(result.status).to eq(:warning)
        expect(result.details[:incompatible]).to contain_exactly(incompatible1, incompatible2)
      end
    end
  end
end
