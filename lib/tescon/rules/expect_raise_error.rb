# frozen_string_literal: true

require_relative "base"
require_relative "call_visitor"

module Tescon
  module Rules
    class ExpectRaiseError < Base
      RULE_NAME = "expect_raise_error"

      class Visitor < CallVisitor
        private

        def finding_for(node)
          return unless expect_raise_error_call?(node)

          expect_node = node.receiver
          matcher_node = matcher(node)
          arguments = matcher_node.arguments.arguments
          return if arguments.empty?

          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert RSpec raise_error expectation to minitest assert_raises",
            start_offset: node.location.start_offset,
            end_offset: node.location.end_offset,
            replacement: replacement_source(arguments, expect_node.block)
          )
        end

        def replacement_source(arguments, block_node)
          args = arguments.map { |argument| argument.location.slice }.join(", ")
          body = block_node.body.location.slice

          "assert_raises(#{args}) { #{body} }"
        end

        def expect_raise_error_call?(node)
          node.name == :to &&
            block_expect_call?(node.receiver) &&
            raise_error_matcher?(matcher(node))
        end

        def block_expect_call?(node)
          node.is_a?(Prism::CallNode) &&
            node.name == :expect &&
            node.receiver.nil? &&
            node.block &&
            node.arguments.nil?
        end

        def raise_error_matcher?(node)
          node.is_a?(Prism::CallNode) &&
            node.name == :raise_error &&
            node.receiver.nil? &&
            node.arguments &&
            !node.arguments.arguments.empty?
        end

        def matcher(node)
          node.arguments&.arguments&.first
        end
      end
    end
  end
end
