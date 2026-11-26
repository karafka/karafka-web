# frozen_string_literal: true

describe_current do
  let(:helper_class) do
    Class.new do
      include Karafka::Web::Ui::Helpers::TimeHelper

      # Mock the kafka_state_badge method since it's not defined in TimeHelper
      def kafka_state_badge(state)
        case state
        when "active"
          "badge-success"
        when "paused"
          "badge-warning"
        else
          "badge-secondary"
        end
      end
    end
  end

  let(:helper) { helper_class.new }

  describe "#relative_time" do
    it "returns a time tag with ISO8601 formatted datetime" do
      time_float = 1_672_531_200.123 # 2023-01-01 00:00:00.123 UTC

      result = helper.relative_time(time_float)
      actual_stamp = Time.at(time_float).getutc.iso8601(3)

      expected = %(<time class="ltr" dir="ltr" title="#{actual_stamp}" ) +
        %(datetime="#{actual_stamp}">#{time_float}</time>)

      assert_equal(expected, result)
    end

    it "handles different time precision" do
      time_float = 1_672_531_200.0

      result = helper.relative_time(time_float)
      actual_stamp = Time.at(time_float).getutc.iso8601(3)

      assert_includes(result, actual_stamp)
      assert_includes(result, time_float.to_s)
    end

    it "properly formats time with milliseconds" do
      time_float = 1_672_531_200.999

      result = helper.relative_time(time_float)
      actual_stamp = Time.at(time_float).getutc.iso8601(3)

      assert_includes(result, actual_stamp)
    end
  end
end
