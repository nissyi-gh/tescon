# frozen_string_literal: true

require_relative "base"
require_relative "call_visitor"

module Tescon
  module Rules
    class Subject < Base
      RULE_NAME = "subject"

      class Visitor < CallVisitor
        private

        def finding_for(node)
          return unless subject_call?(node)

          if named_subject?(node)
            named_subject_finding(node)
          elsif unnamed_subject?(node)
            unnamed_subject_finding(node)
          end
        end

        def subject_call?(node)
          node.name == :subject &&
            node.receiver.nil? &&
            node.block &&
            node.message_loc
        end

        def named_subject?(node)
          arguments = node.arguments&.arguments

          arguments&.length == 1 && arguments.first.is_a?(Prism::SymbolNode)
        end

        def unnamed_subject?(node)
          node.arguments.nil?
        end

        def named_subject_finding(node)
          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert named RSpec subject to minitest let",
            start_offset: node.message_loc.start_offset,
            end_offset: node.message_loc.end_offset,
            replacement: "let"
          )
        end

        def unnamed_subject_finding(node)
          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert unnamed RSpec subject to minitest let",
            start_offset: node.message_loc.start_offset,
            end_offset: node.message_loc.end_offset,
            replacement: "let(:subject)"
          )
        end
      end
    end
  end
end
