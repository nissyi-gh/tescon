# frozen_string_literal: true

module Tescon
  module Trace
    # Normalizes record attributes for portable provenance YAML.
    class AttributeNormalizer
      DEFAULT_EXCLUDED_KEYS = %w[id created_at updated_at].freeze

      def self.normalize(attributes, full: false)
        new(full: full).normalize(attributes)
      end

      def initialize(full: false)
        @full = full
      end

      def normalize(attributes)
        return {} if attributes.nil?

        filtered = if full
                     attributes
                   else
                     attributes.reject { |key, _| DEFAULT_EXCLUDED_KEYS.include?(key.to_s) }
                   end

        filtered.transform_keys(&:to_s).transform_values { |value| normalize_value(value) }
      end

      private

      attr_reader :full

      def normalize_value(value)
        return normalize(value) if value.is_a?(Hash)
        return value.map { |element| normalize_value(element) } if value.is_a?(Array)
        return normalize_time(value) if time_like?(value)
        return value.to_s if defined?(BigDecimal) && value.is_a?(BigDecimal)

        value
      end

      def time_like?(value)
        return true if value.is_a?(Time) || value.is_a?(DateTime)
        return true if defined?(::ActiveSupport::TimeWithZone) && value.is_a?(::ActiveSupport::TimeWithZone)
        return true if value.respond_to?(:utc) && value.utc.is_a?(Time)

        false
      end

      def normalize_time(value)
        if value.respond_to?(:utc)
          value.utc.iso8601(3)
        else
          value.iso8601(3)
        end
      end
    end
  end
end
