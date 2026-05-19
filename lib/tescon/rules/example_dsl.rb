# frozen_string_literal: true

require_relative "base"
require_relative "call_visitor"

module Tescon
  module Rules
    class ExampleDsl < Base
      RULE_NAME = "example_dsl"
      REPLACEMENTS = {
        context: "describe",
        specify: "it"
      }.freeze

      class Visitor < CallVisitor
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
