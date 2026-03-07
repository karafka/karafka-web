# frozen_string_literal: true

describe_current do
  let(:schedule) { described_class.new(attrs) }

  let(:attrs) { { tasks: {} } }

  describe "#tasks" do
    context "when no tasks" do
      it { assert_equal([], schedule.tasks) }
    end

    context "when tasks are present" do
      let(:attrs) do
        {
          tasks: {
            task1: {
              id: "task1",
              cron: "* * * * *"
            }
          }
        }
      end

      it { assert_kind_of(Karafka::Web::Ui::Models::RecurringTasks::Task, schedule.tasks.first) }
      it { assert_kind_of(Array, schedule.tasks) }
      it { assert_equal("task1", schedule.tasks.first.id) }
    end
  end
end
