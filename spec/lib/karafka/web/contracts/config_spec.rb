# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:params) do
    {
      enabled: true,
      ttl: 5000,
      group_id: 'consumer-group-topic',
      topics: {
        errors: {
          name: 'errors-topic',
          config: { 'cleanup.policy': 'delete' }
        },
        consumers: {
          reports: {
            name: 'reports-topic',
            config: { 'cleanup.policy': 'delete' }
          },
          states: {
            name: 'states-topic',
            config: { 'cleanup.policy': 'delete' }
          },
          metrics: {
            name: 'metrics-topic',
            config: { 'cleanup.policy': 'delete' }
          },
          commands: {
            name: 'commands-topic',
            config: { 'cleanup.policy': 'delete' }
          }
        }
      },
      tracking: {
        active: true,
        interval: 2_000,
        consumers: {
          reporter: Object.new,
          sync_threshold: 10,
          sampler: Object.new,
          listeners: []
        },
        producers: {
          reporter: Object.new,
          sampler: Object.new,
          listeners: [],
          sync_threshold: 10
        }
      },
      processing: {
        active: true,
        interval: 3_000,
        kafka: {}
      },
      ui: {
        sessions: {
          key: 'some_key',
          secret: 'a' * 64
        },
        visibility: {
          internal_topics: true,
          active_topics_cluster_lags_only: true
        },
        per_page: 50,
        dlq_patterns: [],
        max_visible_payload_size: 100,
        kafka: {},
        custom: {
          js: false,
          css: false,
          nav_erb: false
        }
      }
    }
  end

  context 'when all values are valid' do
    it 'is valid' do
      expect(contract.call(params)).to be_success
    end
  end

  context 'when enabled is not boolean' do
    before { params[:enabled] = 'string_value' }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when ttl is not numeric' do
    before { params[:ttl] = 'string_value' }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when validating topics topics' do
    context 'when errors topic does not match the regexp' do
      before { params[:topics][:errors][:name] = 'invalid topic!' }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when validating consumer scoped fields' do
      %i[
        reports
        states
        metrics
        commands
      ].each do |field|
        context "when #{field} name does not match the regexp" do
          before { params[:topics][:consumers][field][:name] = 'invalid topic!' }

          it { expect(contract.call(params)).not_to be_success }
        end

        context "when #{field} config contains non-symbol keys" do
          before { params[:topics][:consumers][field][:config] = { 'a' => 'b' } }

          it { expect(contract.call(params)).not_to be_success }
        end

        context "when #{field} config is empty" do
          before { params[:topics][:consumers][field][:config] = {} }

          it { expect(contract.call(params)).not_to be_success }
        end
      end
    end
  end

  context 'when validating tracking related settings' do
    context 'when interval is less than 1000' do
      before { params[:tracking][:interval] = 999 }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when interval is not an integer' do
      before { params[:tracking][:interval] = 1000.5 }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when consumers sync_threshold is less than 0' do
      before { params[:tracking][:consumers][:sync_threshold] = -1 }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when consumers sync_threshold is not an integer' do
      before { params[:tracking][:consumers][:sync_threshold] = 1.1 }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when producers sync_threshold is less than 0' do
      before { params[:tracking][:producers][:sync_threshold] = -1 }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when producers sync_threshold is not an integer' do
      before { params[:tracking][:producers][:sync_threshold] = 1.1 }

      it { expect(contract.call(params)).not_to be_success }
    end

    %i[consumers producers].each do |entity|
      context "when checking #{entity} scoped data" do
        %i[reporter sampler].each do |field|
          context "when #{field} is nil" do
            before { params[:tracking][entity][field] = nil }

            it { expect(contract.call(params)).not_to be_success }
          end
        end

        context 'when listeners is not an array' do
          before { params[:tracking][entity][:listeners] = 'not_an_array' }

          it { expect(contract.call(params)).not_to be_success }
        end
      end
    end
  end

  context 'when validating processing related settings' do
    context 'when active is not a boolean' do
      before { params[:processing][:active] = 'maybe' }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when group_id does not match the regexp' do
      before { params[:group_id] = 'invalid topic!' }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when interval is less than 1000' do
      before { params[:processing][:interval] = 999 }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when kafka is nil' do
      before { params[:processing][:kafka] = nil }

      it { expect(contract.call(params)).not_to be_success }
    end
  end

  context 'when validating ui related settings' do
    context 'when validating sessions related settings' do
      context 'when key is empty' do
        before { params[:ui][:sessions][:key] = '' }

        it { expect(contract.call(params)).not_to be_success }
      end

      context 'when secret is less than 64 characters long' do
        before { params[:ui][:sessions][:secret] = 'short' }

        it { expect(contract.call(params)).not_to be_success }
      end
    end

    context 'when kafka is nil' do
      before { params[:ui][:kafka] = nil }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when per_page is more than 100' do
      before { params[:ui][:per_page] = 101 }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when per_page is less than 1' do
      before { params[:ui][:per_page] = 0 }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when internal_topics is nil' do
      before { params[:ui][:visibility][:internal_topics] = nil }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when internal_topics is not boolean' do
      before { params[:ui][:visibility][:internal_topics] = '1' }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when active_topics_cluster_lags_only is nil' do
      before { params[:ui][:visibility][:active_topics_cluster_lags_only] = nil }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when active_topics_cluster_lags_only is not boolean' do
      before { params[:ui][:visibility][:active_topics_cluster_lags_only] = '1' }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when max_visible_payload_size is not an integer' do
      before { params[:ui][:max_visible_payload_size] = '1' }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when max_visible_payload_size is less than 1' do
      before { params[:ui][:max_visible_payload_size] = 0 }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when dlq_patterns is not an array' do
      before { params[:ui][:dlq_patterns] = '1' }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when dlq_patterns is array with things other than string or regexp' do
      before { params[:ui][:dlq_patterns] = [1, 2, 3] }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when validating custom UI config options' do
      %i[js css nav_erb].each do |key|
        context "when checking custom.#{key}" do
          context 'when set to false' do
            before { params[:ui][:custom][key] = false }

            it { expect(contract.call(params)).to be_success }
          end

          context 'when set to an empty string' do
            before { params[:ui][:custom][key] = '' }

            it { expect(contract.call(params)).not_to be_success }
          end

          context 'when set to a non-empty string' do
            before { params[:ui][:custom][key] = 'something.valid' }

            it { expect(contract.call(params)).to be_success }
          end

          context 'when set to an invalid type' do
            before { params[:ui][:custom][key] = 123 }

            it { expect(contract.call(params)).not_to be_success }
          end
        end
      end
    end
  end
end
