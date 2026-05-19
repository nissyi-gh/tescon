# frozen_string_literal: true

require_relative "base"
require_relative "call_visitor"

module Tescon
  module Rules
    class RspecDescribe < Base
      RULE_NAME = "rspec_describe"

      class Visitor < CallVisitor
        private

        def finding_for(node)
          return unless rspec_describe_call?(node)

          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert RSpec.describe to minitest describe",
            start_offset: node.receiver.location.start_offset,
            end_offset: node.message_loc.end_offset,
            replacement: "describe"
          )
        end

        def rspec_describe_call?(node)
          node.name == :describe &&
            node.receiver.is_a?(Prism::ConstantReadNode) &&
            node.receiver.name == :RSpec &&
            node.message_loc
        end
      end
    end
  end
end
