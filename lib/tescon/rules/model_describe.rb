# frozen_string_literal: true

require_relative "base"
require_relative "call_visitor"
require_relative "describe_helpers"

module Tescon
  module Rules
    class ModelDescribe < Base
      RULE_NAME = "model_describe"
      BASE_CLASS = "ActiveSupport::TestCase"
      DSL_EXTEND = "extend Minitest::Spec::DSL"

      class Visitor < CallVisitor
        private

        def finding_for(node)
          return unless model_describe_call?(node)

          subject = node.arguments.arguments.first.slice
          replacement = "class #{subject}Test < #{BASE_CLASS}\n  #{DSL_EXTEND}\n"

          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert model describe to ActiveSupport::TestCase",
            start_offset: node.location.start_offset,
            end_offset: node.block.opening_loc.end_offset,
            replacement: replacement
          )
        end

        def model_describe_call?(node)
          return false unless node.name == :describe
          return false unless node.block&.opening_loc
          return false unless describe_receiver?(node.receiver)
          return false unless DescribeHelpers.model_type?(node)
          return false unless DescribeHelpers.constant_subject?(node)

          true
        end

        def describe_receiver?(receiver)
          receiver.nil? ||
            (receiver.is_a?(Prism::ConstantReadNode) && receiver.name == :RSpec)
        end
      end
    end
  end
end
