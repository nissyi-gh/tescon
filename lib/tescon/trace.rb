# frozen_string_literal: true

require_relative "trace/config"
require_relative "trace/provenance"
require_relative "trace/attribute_normalizer"
require_relative "trace/recorder"
require_relative "trace/yaml_writer"
require_relative "trace/factory_bot"
require_relative "trace/active_record"
require_relative "trace/rspec"

module Tescon
  # Runtime tracing for FactoryBot and ActiveRecord during RSpec examples.
  module Trace
    class << self
      def recorder
        @recorder ||= Recorder.new
      end

      def config
        @config ||= Config.new
      end

      def reset!
        @recorder = Recorder.new
      end

      def install!
        FactoryBot.install! if defined?(::FactoryBot)
        ActiveRecord.install! if defined?(::ActiveRecord)
        RSpec.install! if defined?(::RSpec)
      end
    end

    install!
  end
end
