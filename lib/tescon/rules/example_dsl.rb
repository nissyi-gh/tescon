# frozen_string_literal: true

require "prism"

module Tescon
  module Rules
    # Converts RSpec example DSL method names to minitest-spec names.
    class ExampleDsl
      RULE_NAME = "example_dsl"
      REPLACEMENTS = {
        context: "describe",
        specify: "it"
      }.freeze

      def analyze(source_file)
        Visitor.findings(source_file)
      end

      class Visitor < Prism::Visitor
        def self.findings(source_file)
          new.tap { |visitor| visitor.visit(Prism.parse(source_file.source).value) }.findings
        end

        attr_reader :findings

        def initialize
          @findings = []
          super
        end

        def visit_call_node(node)
          finding = finding_for(node)
          @findings << finding if finding

          super
        end

        private

        def finding_for(node)
          replacement = REPLACEMENTS[node.name]
          return unless replacement
          return unless node.receiver.nil?
          return unless node.message_loc

          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert RSpec example DSL to minitest-spec DSL",
            start_offset: node.message_loc.start_offset,
            end_offset: node.message_loc.end_offset,
            replacement: replacement
          )
        end
      end
    end
  end
end
