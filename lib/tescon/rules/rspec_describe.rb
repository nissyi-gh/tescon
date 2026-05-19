# frozen_string_literal: true

require "prism"

module Tescon
  module Rules
    # Finds RSpec.describe calls that can be translated to minitest describe calls.
    class RspecDescribe
      RULE_NAME = "rspec_describe"

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
