# frozen_string_literal: true

RSpec.describe Karafka::Web::Ui::Helpers::TimeHelper do
  let(:helper_class) do
    Class.new do
      include Karafka::Web::Ui::Helpers::TimeHelper

      # Mock the kafka_state_badge method since it's not defined in TimeHelper
      def kafka_state_badge(state)
        case state
        when 'active'
          'badge-success'
        when 'paused'
          'badge-warning'
        else
          'badge-secondary'
        end
      end
    end
  end

  let(:helper) { helper_class.new }

  describe '#relative_time' do
    it 'returns a time tag with ISO8601 formatted datetime' do
      time_float = 1_672_531_200.123 # 2023-01-01 00:00:00.123 UTC

      result = helper.relative_time(time_float)
      actual_stamp = Time.at(time_float).getutc.iso8601(3)

      expect(result).to eq(
        %(<time class="ltr" dir="ltr" title="#{actual_stamp}" datetime="#{actual_stamp}">#{time_float}</time>)
      )
    end

    it 'handles different time precision' do
      time_float = 1_672_531_200.0

      result = helper.relative_time(time_float)
      actual_stamp = Time.at(time_float).getutc.iso8601(3)

      expect(result).to include(actual_stamp)
      expect(result).to include(time_float.to_s)
    end

    it 'properly formats time with milliseconds' do
      time_float = 1_672_531_200.999

      result = helper.relative_time(time_float)
      actual_stamp = Time.at(time_float).getutc.iso8601(3)

      expect(result).to include(actual_stamp)
    end
  end

  describe '#time_with_label' do
    it 'returns a span tag with millisecond timestamp title' do
      time = Time.new(2023, 1, 1, 12, 30, 45.123, '+00:00')
      expected_stamp = (time.to_f * 1_000).to_i

      result = helper.time_with_label(time)

      expect(result).to eq(%(<span title="#{expected_stamp}">#{time}</span>))
    end

    it 'converts time to milliseconds correctly' do
      time = Time.at(1_672_531_200.123)
      expected_ms = 1_672_531_200_123

      result = helper.time_with_label(time)

      expect(result).to include("title=\"#{expected_ms}\"")
    end

    it 'handles time objects with different precisions' do
      time = Time.at(1_672_531_200)
      expected_ms = 1_672_531_200_000

      result = helper.time_with_label(time)

      expect(result).to include("title=\"#{expected_ms}\"")
    end
  end

  describe '#human_readable_time' do
    context 'when seconds are less than 60' do
      it 'returns seconds with appropriate decimal places' do
        expect(helper.human_readable_time(0)).to eq('0 seconds')
        expect(helper.human_readable_time(30.5)).to eq('30.5 seconds')
      end
    end

    context 'when seconds are between 60 and 3599 (1 minute to 59 minutes)' do
      it 'returns minutes with 2 decimal places' do
        expect(helper.human_readable_time(60)).to eq('1.0 minutes')
        expect(helper.human_readable_time(90)).to eq('1.5 minutes')
        expect(helper.human_readable_time(1800)).to eq('30.0 minutes')
        expect(helper.human_readable_time(3599)).to eq('59.98 minutes')
      end
    end

    context 'when seconds are between 3600 and 86399 (1 hour to 23 hours)' do
      it 'returns hours with 2 decimal places' do
        expect(helper.human_readable_time(3600)).to eq('1.0 hours')
        expect(helper.human_readable_time(7200)).to eq('2.0 hours')
        expect(helper.human_readable_time(5400)).to eq('1.5 hours')
        expect(helper.human_readable_time(86_399)).to eq('24.0 hours')
      end
    end

    context 'when seconds are 86400 or more (1 day or more)' do
      it 'returns days with 2 decimal places' do
        expect(helper.human_readable_time(86_400)).to eq('1.0 days')
        expect(helper.human_readable_time(172_800)).to eq('2.0 days')
        expect(helper.human_readable_time(129_600)).to eq('1.5 days')
        expect(helper.human_readable_time(1_000_000)).to eq('11.57 days')
      end
    end

    it 'handles edge cases at boundaries' do
      # Test the actual behavior of the method at boundaries
      expect(helper.human_readable_time(59)).to eq('59 seconds')
      expect(helper.human_readable_time(60)).to eq('1.0 minutes')
      expect(helper.human_readable_time(3600)).to eq('1.0 hours')
      expect(helper.human_readable_time(86_400)).to eq('1.0 days')
    end
  end

  describe '#poll_state_with_change_time_label' do
    let(:year_in_seconds) { 131_556_926 }

    context 'when state is active' do
      it 'returns badge without title or time information' do
        result = helper.poll_state_with_change_time_label('active', 1_000)

        expect(result.strip).to eq(
          %(<span class="badge badge-success">active</span>)
        )
      end
    end

    context 'when state is not active and state_ch is greater than a year' do
      it 'returns badge with "until manual resume" title' do
        state_ch = (year_in_seconds + 1_000) * 1_000 # Convert to milliseconds

        result = helper.poll_state_with_change_time_label('paused', state_ch)

        # Check for key components instead of exact match due to whitespace
        expect(result).to include('class="badge badge-warning"')
        expect(result).to include('title="until manual resume"')
        expect(result).to include('paused')
      end
    end

    context 'when state is not active and state_ch is less than a year' do
      it 'returns badge with future time title' do
        state_ch = 5000 # 5 seconds in milliseconds
        current_time = Time.now

        allow(Time).to receive(:now).and_return(current_time)

        result = helper.poll_state_with_change_time_label('paused', state_ch)
        expected_time = current_time + (state_ch / 1_000.0)

        # Check for key components instead of exact match due to whitespace
        expect(result).to include('class="badge badge-warning time-title"')
        expect(result).to include("title=\"#{expected_time}\"")
        expect(result).to include('paused')
      end

      it 'correctly calculates future time from current time' do
        state_ch = 10_000 # 10 seconds in milliseconds
        freeze_time = Time.new(2023, 1, 1, 12, 0, 0)

        allow(Time).to receive(:now).and_return(freeze_time)

        result = helper.poll_state_with_change_time_label('paused', state_ch)
        expected_time = freeze_time + 10

        expect(result).to include("title=\"#{expected_time}\"")
      end
    end

    context 'with different states' do
      it 'works with different state values' do
        result = helper.poll_state_with_change_time_label('suspended', 1_000)

        expect(result).to include('class="badge badge-secondary time-title"')
        expect(result).to include('suspended')
      end
    end

    context 'when testing edge cases' do
      it 'handles exactly one year threshold' do
        state_ch = (131_556_926 + 1) * 1_000 # Just over one year in milliseconds

        result = helper.poll_state_with_change_time_label('paused', state_ch)

        expect(result).to include('title="until manual resume"')
      end

      it 'handles zero state_ch value' do
        allow(Time).to receive(:now).and_return(Time.new(2023, 1, 1))

        result = helper.poll_state_with_change_time_label('paused', 0)

        expect(result).to include('time-title')
        expect(result).to include('2023-01-01')
      end
    end
  end
end
