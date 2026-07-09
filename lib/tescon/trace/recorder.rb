# frozen_string_literal: true

require_relative "provenance"

module Tescon
  module Trace
    # Collects factory calls and inserted records per RSpec example.
    class Recorder
      def initialize
        @examples = []
        @current_example = nil
        @factory_call_stack = []
      end

      attr_reader :examples

      def start_example(id:, file:, line:, description:)
        finish_example if current_example

        @current_example = ExampleTrace.new(
          id: id,
          file: file,
          line: line,
          description: description
        )
      end

      def finish_example
        return unless current_example

        @examples << current_example
        @current_example = nil
        @factory_call_stack = []
      end

      def enter_factory_call(caller:, strategy:, factory_name:, traits: [], overrides: {})
        raise Error, "no active example" unless current_example

        call = FactoryCall.new(
          strategy: strategy,
          factory_name: factory_name,
          traits: traits,
          overrides: overrides,
          caller: caller
        )
        current_example.factory_calls << call
        factory_call_stack << call
        call
      end

      def exit_factory_call
        factory_call_stack.pop
      end

      def record_insert(model:, table:, id:, attributes:)
        raise Error, "no active example" unless current_example

        classification = factory_call_stack.empty? ? :side_effect : :setup
        snapshot = RecordSnapshot.new(
          model: model,
          table: table,
          id: id,
          attributes: attributes,
          classification: classification.to_s
        )

        if factory_call_stack.empty?
          current_example.side_effect_records << snapshot
        else
          factory_call_stack.last.records << snapshot
        end

        snapshot
      end

      def to_h
        {
          "examples" => examples.map { |example| example_to_h(example) }
        }
      end

      private

      attr_reader :current_example, :factory_call_stack

      def example_to_h(example)
        {
          "id" => example.id,
          "file" => example.file,
          "line" => example.line,
          "description" => example.description,
          "factory_calls" => example.factory_calls.map { |call| factory_call_to_h(call) },
          "side_effect_records" => example.side_effect_records.map { |record| record_to_h(record) }
        }
      end

      def factory_call_to_h(call)
        {
          "strategy" => call.strategy.to_s,
          "factory" => call.factory_name.to_s,
          "traits" => call.traits.map(&:to_s),
          "overrides" => call.overrides,
          "caller" => call.caller,
          "records" => call.records.map { |record| record_to_h(record) }
        }
      end

      def record_to_h(record)
        {
          "model" => record.model,
          "table" => record.table,
          "id" => record.id,
          "attributes" => record.attributes,
          "classification" => record.classification
        }
      end
    end
  end
end
