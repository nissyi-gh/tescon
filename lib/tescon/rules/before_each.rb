# frozen_string_literal: true

require_relative "base"
require_relative "call_visitor"

module Tescon
  module Rules
    class BeforeEach < Base
      RULE_NAME = "before_each"
      HOOKS = %i[before after].freeze

      class Visitor < CallVisitor
        private

        def finding_for(node)
          return unless each_hook?(node)

          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert RSpec #{node.name}(:each) to minitest-spec #{node.name}",
            start_offset: node.message_loc.start_offset,
            end_offset: node.closing_loc.end_offset,
            replacement: node.name.to_s
          )
        end

        def each_hook?(node)
          HOOKS.include?(node.name) &&
            node.receiver.nil? &&
            node.block &&
            node.message_loc &&
            node.closing_loc &&
            node.arguments&.arguments&.length == 1 &&
            node.arguments.arguments.first.is_a?(Prism::SymbolNode) &&
            node.arguments.arguments.first.unescaped == "each"
        end
      end
    end
  end
end
