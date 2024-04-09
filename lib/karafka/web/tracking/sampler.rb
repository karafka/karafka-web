# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      # Base sampler with some basic info collectors
      # This sampler should store **only** collectors that can be used for producers, consumers and
      # the Web-UI itself. All specific to a given aspect of operations should be moved out.
      class Sampler
        # @return [String] Unique process identifier
        def process_id
          @process_id ||= "#{Socket.gethostname}:#{::Process.pid}:#{SecureRandom.hex(6)}"
        end

        # @return [String] currently used ruby version with details
        def ruby_version
          return @ruby_version if @ruby_version

          if defined?(JRUBY_VERSION)
            revision = JRUBY_REVISION.to_s
            version = JRUBY_VERSION
          else
            revision = RUBY_REVISION.to_s
            version = RUBY_ENGINE_VERSION
          end

          @ruby_version = "#{RUBY_ENGINE} #{version}-#{RUBY_PATCHLEVEL} #{revision[0..5]}"
        end

        # @return [String] Karafka version
        def karafka_version
          ::Karafka::VERSION
        end

        # @return [String] Karafka Web UI version
        def karafka_web_version
          ::Karafka::Web::VERSION
        end

        # @return [String] Karafka::Core version
        def karafka_core_version
          ::Karafka::Core::VERSION
        end

        # @return [String] rdkafka version
        def rdkafka_version
          ::Rdkafka::VERSION
        end

        # @return [String] librdkafka version
        def librdkafka_version
          ::Rdkafka::LIBRDKAFKA_VERSION
        end

        # @return [String] WaterDrop version
        def waterdrop_version
          ::WaterDrop::VERSION
        end
      end
    end
  end
end
