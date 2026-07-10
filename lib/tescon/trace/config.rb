# frozen_string_literal: true

module Tescon
  module Trace
    # Runtime configuration for provenance tracing.
    class Config
      DEFAULT_OUTPUT_DIR = "tmp/tescon/provenance"
      TRUTHY_VALUES = %w[1 true yes].freeze

      def full_attributes?
        truthy?(ENV["TESCON_TRACE_FULL_ATTRIBUTES"])
      end

      def output_dir
        ENV.fetch("TESCON_TRACE_PATH", DEFAULT_OUTPUT_DIR)
      end

      def project_root
        if defined?(::Rails) && ::Rails.respond_to?(:root)
          ::Rails.root.to_s
        else
          Dir.pwd
        end
      end

      private

      def truthy?(value)
        return false if value.nil? || value.empty?

        TRUTHY_VALUES.include?(value.to_s.downcase)
      end
    end
  end
end
