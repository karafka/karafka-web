# frozen_string_literal: true

# A simple wrapper to get fixtures both in plain text and in JSON if needed
class Fixtures
  class << self
    # Builds the fixtures file path
    #
    # @param file_name [String] fixture file name
    # @return [Pathname] path to the fixture file
    def path(file_name)
      File
        .dirname(__FILE__)
        .then { |location| File.join(location, '../', 'fixtures', file_name) }
    end

    # Fetches fixture content
    #
    # @param file_name [String] fixture file name
    # @return [String] fixture content
    def file(file_name)
      path(file_name).then { |fixture_path| File.read(fixture_path) }
    end

    # Fetches and parses to JSON data from the fixture file
    #
    # @param file_name [String] fixture file name without extension because `.json` expected
    # @param symbolize_names [Boolean] should we parse to symbols
    # @return [Array, Hash] deserialized JSON data
    def json(file_name, symbolize_names: true)
      JSON.parse(
        file("#{file_name}.json"),
        symbolize_names: symbolize_names
      )
    end

    %i[
      consumers_reports
      consumers_metrics
      consumers_states
      consumers_commands
      errors
      recurring_tasks_schedules
      recurring_tasks_logs
      scheduled_messages_states
      scheduled_messages
    ].each do |type|
      define_method :"#{type}_file" do |name = 'current.json'|
        file("#{type}/#{name}")
      end

      define_method :"#{type}_msg" do |name = 'current'|
        file("#{type}/#{name}.msg")
      end

      define_method :"#{type}_json" do |name = 'current', symbolize_names: true|
        json("#{type}/#{name}", symbolize_names: symbolize_names)
      end
    end
  end
end
