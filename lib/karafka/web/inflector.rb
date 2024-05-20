# frozen_string_literal: true

module Karafka
  module Web
    # Web UI Zeitwerk Inflector that allows us to have time prefixed files with migrations, similar
    # to how Rails does that.
    class Inflector < Zeitwerk::GemInflector
      # Checks if given path is a migration one
      MIGRATION_ABSPATH_REGEXP = /migrations\/[a-z_]+\/[0-9]+_(.*)/

      # Checks if it is a migration file
      MIGRATION_BASENAME_REGEXP = /\A[0-9]+_(.*)/

      private_constant :MIGRATION_ABSPATH_REGEXP, :MIGRATION_BASENAME_REGEXP

      # @param [String] basename of the file to be loaded
      # @param abspath [String] absolute path of the file to be loaded
      # @return [String] Constant name to be used for given file
      def camelize(basename, abspath)
        # If not migration directory with proper migration files, use defaults
        return super unless abspath.match?(MIGRATION_ABSPATH_REGEXP)
        # If base name is not of a proper name in migrations, use defaults
        return super unless basename.match?(MIGRATION_BASENAME_REGEXP)

        super(
          # Extract only the name without the timestamp
          basename.match(MIGRATION_BASENAME_REGEXP).to_a.last,
          abspath
        )
      end
    end
  end
end
