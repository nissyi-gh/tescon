# frozen_string_literal: true

require "prism"

module Tescon
  module Rules
    # Finds RSpec eq expectations that can be translated to minitest assertions.
    class ExpectEq
      RULE_NAME = "expect_eq"

      def analyze(source_file)
        Visitor.findings(source_file)
      end

      class Visitor < Prism::Visitor
        def self.findings(source_file)
          new(source_file).tap { |visitor| visitor.visit(Prism.parse(source_file.source).value) }.findings
        end

        attr_reader :findings

        def initialize(source_file)
          @source_file = source_file
          @findings = []
          super()
        end

        def visit_call_node(node)
          finding = finding_for(node)
          @findings << finding if finding

          super
        end

        private

        attr_reader :source_file

        def finding_for(node)
          expectation_method = expectation_method_for(node)
          return unless expectation_method

          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert RSpec eq expectation to minitest equality assertion",
            start_offset: node.location.start_offset,
            end_offset: node.location.end_offset,
            replacement: replacement_source(node, expectation_method)
          )
        end

        def replacement_source(node, expectation_method)
          expect_arg = node.receiver.arguments.arguments.first
          eq_arg = eq_matcher(node).arguments.arguments.first

          "expect(#{expect_arg.location.slice}).#{expectation_method} #{eq_arg.location.slice}"
        end

        def expectation_method_for(node)
          return unless expect_eq_call?(node)

          { to: "must_equal", not_to: "wont_equal" }[node.name]
        end

        def expect_eq_call?(node)
          %i[to not_to].include?(node.name) &&
            expect_call?(node.receiver) &&
            eq_matcher?(eq_matcher(node))
        end

        def expect_call?(node)
          node.is_a?(Prism::CallNode) &&
            node.name == :expect &&
            node.receiver.nil? &&
            node.arguments&.arguments&.length == 1
        end

        def eq_matcher?(node)
          node.is_a?(Prism::CallNode) &&
            node.name == :eq &&
            node.receiver.nil? &&
            node.arguments&.arguments&.length == 1
        end

        def eq_matcher(node)
          node.arguments&.arguments&.first
        end
      end
    end
  end
end
