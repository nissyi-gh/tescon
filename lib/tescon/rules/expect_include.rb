# frozen_string_literal: true

require "prism"

module Tescon
  module Rules
    # Finds RSpec include expectations that can be translated to minitest assertions.
    class ExpectInclude
      RULE_NAME = "expect_include"

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
          super()
        end

        def visit_call_node(node)
          finding = finding_for(node)
          @findings << finding if finding

          super
        end

        private

        def finding_for(node)
          expectation_method = expectation_method_for(node)
          return unless expectation_method

          expect_arg = node.receiver.arguments.arguments.first
          include_arg = matcher(node).arguments.arguments.first

          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert RSpec include expectation to minitest include assertion",
            start_offset: node.location.start_offset,
            end_offset: node.location.end_offset,
            replacement: "expect(#{expect_arg.location.slice}).#{expectation_method} #{include_arg.location.slice}"
          )
        end

        def expectation_method_for(node)
          return unless expect_include_call?(node)

          { to: "must_include", not_to: "wont_include" }[node.name]
        end

        def expect_include_call?(node)
          %i[to not_to].include?(node.name) &&
            expect_call?(node.receiver) &&
            include_matcher?(matcher(node))
        end

        def expect_call?(node)
          node.is_a?(Prism::CallNode) &&
            node.name == :expect &&
            node.receiver.nil? &&
            node.arguments&.arguments&.length == 1
        end

        def include_matcher?(node)
          node.is_a?(Prism::CallNode) &&
            node.name == :include &&
            node.receiver.nil? &&
            node.arguments&.arguments&.length == 1
        end

        def matcher(node)
          node.arguments&.arguments&.first
        end
      end
    end
  end
end
