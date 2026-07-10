# frozen_string_literal: true

require_relative "provenance"
require_relative "attribute_normalizer"
require_relative "path_normalizer"

module Tescon
  module Trace
    # Collects factory calls and inserted records per RSpec example.
    class Recorder
      def initialize
        @examples = []
        @current_example = nil
        @factory_call_stack = []
        @call_counter = 0
      end

      attr_reader :examples

      def start_example(id:, file:, line:, description:, full_description: nil)
        finish_example if current_example

        @call_counter = 0
        @current_example = ExampleTrace.new(
          id: id,
          file: file,
          line: line,
          description: description,
          full_description: full_description
        )
      end

      def finish_example
        return unless current_example

        @examples << current_example
        @current_example = nil
        @factory_call_stack = []
        @call_counter = 0
      end

      def enter_factory_call(caller:, strategy:, factory_name:, traits: [], overrides: {}, count: nil) # rubocop:disable Metrics/ParameterLists
        raise Error, "no active example" unless current_example

        @call_counter += 1
        parent = factory_call_stack.last
        call = FactoryCall.new(
          call_id: @call_counter,
          parent_call_id: parent&.call_id,
          strategy: strategy,
          factory_name: factory_name,
          traits: traits,
          overrides: overrides,
          caller: PathNormalizer.relativize_caller(caller),
          count: count
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
        via = factory_call_stack.size > 1 ? "association" : nil
        caller = PathNormalizer.relativize_caller(Tescon::Trace::FactoryBot::CallerLocation.format) if classification == :side_effect
        links = build_links(attributes)

        snapshot = RecordSnapshot.new(
          model: model,
          table: table,
          id: id,
          attributes: attributes,
          classification: classification.to_s,
          caller: caller,
          via: via,
          links: links
        )

        if factory_call_stack.empty?
          current_example.side_effect_records << snapshot
        else
          factory_call_stack.last.records << snapshot
        end

        snapshot
      end

      def examples_by_file
        examples.group_by(&:file)
      end

      def to_h(examples: self.examples)
        {
          "examples" => examples.map { |example| example_to_h(example) }
        }
      end

      def example_hashes(examples: self.examples)
        examples.map { |example| example_to_h(example) }
      end

      private

      attr_reader :current_example, :factory_call_stack

      def build_links(attributes)
        known_records = collect_known_records
        attributes.each_with_object([]) do |(key, value), links|
          next unless key.to_s.end_with?("_id") && value

          matching = known_records.find { |record| record.id == value }
          next unless matching

          links << {
            "attribute" => key.to_s,
            "target_model" => matching.model,
            "target_id" => matching.id
          }
        end
      end

      def collect_known_records
        return [] unless current_example

        records = current_example.factory_calls.flat_map(&:records)
        records + current_example.side_effect_records
      end

      def example_to_h(example)
        hash = {
          "id" => example.id,
          "file" => PathNormalizer.relativize(example.file),
          "line" => example.line,
          "description" => example.description,
          "factory_calls" => example.factory_calls.map { |call| factory_call_to_h(call) },
          "side_effect_records" => example.side_effect_records.map { |record| record_to_h(record) }
        }
        hash["full_description"] = example.full_description if example.full_description
        hash
      end

      def factory_call_to_h(call)
        hash = {
          "call_id" => call.call_id,
          "strategy" => call.strategy.to_s,
          "factory" => call.factory_name.to_s,
          "traits" => call.traits.map(&:to_s),
          "overrides" => call.overrides,
          "caller" => call.caller,
          "records" => call.records.map { |record| record_to_h(record) }
        }
        hash["parent_call_id"] = call.parent_call_id if call.parent_call_id
        hash["count"] = call.count if call.count
        hash
      end

      def record_to_h(record)
        hash = {
          "model" => record.model,
          "table" => record.table,
          "id" => record.id,
          "attributes" => AttributeNormalizer.normalize(
            record.attributes,
            full: Tescon::Trace.config.full_attributes?
          ),
          "classification" => record.classification
        }
        hash["caller"] = record.caller if record.caller
        hash["via"] = record.via if record.via
        hash["links"] = record.links if record.links.any?
        hash
      end
    end
  end
end
