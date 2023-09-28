# frozen_string_literal: true

# A simple wrapper to get fixtures both in plain text and in JSON if needed
class Fixtures
  class << self
    # Fetches fixture content
    #
    # @param file_name [String] fixture file name
    # @return [String] fixture content
    def file(file_name)
      File
        .dirname(__FILE__)
        .then { |location| File.join(location, '../', 'fixtures', file_name) }
        .then { |fixture_path| File.read(fixture_path) }
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
  end
end
