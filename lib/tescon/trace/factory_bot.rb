# frozen_string_literal: true

require_relative "path_normalizer"

module Tescon
  module Trace
    # Patches FactoryBot create APIs to record provenance.
    module FactoryBot
      module Methods
        def create(*args, **kwargs, &block)
          trace_factory_call(:create, *args, **kwargs) { super(*args, **kwargs, &block) }
        end

        def create_list(*args, **kwargs, &block)
          factory_name, traits, overrides, count = ArgumentParser.parse_list(*args, **kwargs)
          return super(*args, **kwargs, &block) unless factory_name

          trace_entered = false
          begin
            Tescon::Trace.recorder.enter_factory_call(
              strategy: :create_list,
              factory_name: factory_name,
              traits: traits,
              overrides: overrides,
              count: count,
              caller: CallerLocation.format
            )
            trace_entered = true
            super(*args, **kwargs, &block)
          ensure
            Tescon::Trace.recorder.exit_factory_call if trace_entered
          end
        end

        private

        def trace_factory_call(strategy, *args, **kwargs)
          factory_name, traits, overrides = ArgumentParser.parse(*args, **kwargs)
          return yield unless factory_name

          trace_entered = false
          begin
            Tescon::Trace.recorder.enter_factory_call(
              strategy: strategy,
              factory_name: factory_name,
              traits: traits,
              overrides: overrides,
              caller: CallerLocation.format
            )
            trace_entered = true
            yield
          ensure
            Tescon::Trace.recorder.exit_factory_call if trace_entered
          end
        end
      end

      module ArgumentParser
        module_function

        def parse(*args, **kwargs)
          remaining = args.dup
          factory_name = shift_factory_name(remaining)
          traits = shift_traits(remaining)
          overrides = kwargs.dup
          overrides.merge!(remaining.shift) if remaining.first.is_a?(Hash)

          [factory_name, traits, stringify_keys(overrides)]
        end

        def parse_list(*args, **kwargs)
          remaining = args.dup
          factory_name = shift_factory_name(remaining)
          count = remaining.first.is_a?(Integer) ? remaining.shift : nil
          traits = shift_traits(remaining)
          overrides = kwargs.dup
          overrides.merge!(remaining.shift) if remaining.first.is_a?(Hash)

          [factory_name, traits, stringify_keys(overrides), count]
        end

        def stringify_keys(hash)
          hash.transform_keys(&:to_s)
        end

        def shift_factory_name(args)
          return unless args.first.is_a?(Symbol) || args.first.is_a?(String)

          args.shift.to_sym
        end

        def shift_traits(args)
          traits = []
          traits << args.shift.to_sym while args.first.is_a?(Symbol) || trait_string?(args.first)
          traits
        end

        def trait_string?(value)
          value.is_a?(String) && !value.include?("=")
        end
      end

      module CallerLocation
        INTERNAL_PATH_PATTERNS = %w[
          tescon/trace
          active_record
          activerecord
          factory_bot
        ].freeze

        module_function

        def format
          location = caller_locations.find do |entry|
            !internal_frame?(entry)
          end
          return PathNormalizer::FACTORY_BOT_CALLER unless location

          PathNormalizer.sanitize_caller("#{location.path}:#{location.lineno}")
        end

        def internal_frame?(entry)
          path = entry.path
          return true if INTERNAL_PATH_PATTERNS.any? { |pattern| path.include?(pattern) }
          return true if gem_path?(path)

          false
        end

        def gem_path?(path)
          expanded = File.expand_path(path)
          expanded.include?("/gems/") || expanded.include?("/vendor/bundle/")
        end
      end

      def self.install!
        return if @installed

        ::FactoryBot.singleton_class.prepend(Methods)
        ::FactoryBot::Syntax::Methods.prepend(Methods) if defined?(::FactoryBot::Syntax::Methods)
        @installed = true
      end
    end
  end
end
