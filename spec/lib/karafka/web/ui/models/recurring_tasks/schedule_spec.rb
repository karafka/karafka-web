# frozen_string_literal: true

RSpec.describe_current do
  subject(:schedule) { described_class.new(attrs) }

  let(:attrs) { { tasks: {} } }

  describe '#tasks' do
    context 'when no tasks' do
      it { expect(schedule.tasks).to eq([]) }
    end

    context 'when tasks are present' do
      let(:attrs) do
        {
          tasks: {
            task1: {
              id: 'task1',
              cron: '* * * * *'
            }
          }
        }
      end

      it { expect(schedule.tasks.first).to be_a(Karafka::Web::Ui::Models::RecurringTasks::Task) }
      it { expect(schedule.tasks).to be_a(Array) }
      it { expect(schedule.tasks.first.id).to eq('task1') }
    end
  end
end
