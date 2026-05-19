# frozen_string_literal: true

require_relative "base"
require_relative "call_visitor"

module Tescon
  module Rules
    class LetBang < Base
      RULE_NAME = "let_bang"

      class Visitor < CallVisitor
        private

        def finding_for(node)
          return unless let_bang_call?(node)

          name = node.arguments.arguments.first.unescaped
          indent = indent_for(node)

          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert RSpec let! to minitest-spec let with before hook",
            start_offset: line_start_offset(node.location.start_offset),
            end_offset: node.location.end_offset,
            replacement: "#{indent}let(:#{name}) #{node.block.location.slice}\n#{indent}before { #{name} }"
          )
        end

        def indent_for(node)
          line_index = source_file.source.byteslice(0, node.location.start_offset).count("\n")
          source_file.source.lines[line_index][/\A(\s*)/, 1]
        end

        def line_start_offset(offset)
          index = source_file.source.rindex("\n", offset - 1)
          index ? index + 1 : 0
        end

        def let_bang_call?(node)
          node.name == :let! &&
            node.receiver.nil? &&
            node.block &&
            node.arguments&.arguments&.length == 1 &&
            node.arguments.arguments.first.is_a?(Prism::SymbolNode)
        end
      end
    end
  end
end
