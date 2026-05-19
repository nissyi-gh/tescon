# frozen_string_literal: true

require "prism"

module Tescon
  module Rules
    # Finds RSpec be_nil expectations that can be translated to minitest assertions.
    class ExpectBeNil
      RULE_NAME = "expect_be_nil"

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

          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert RSpec be_nil expectation to minitest nil assertion",
            start_offset: node.location.start_offset,
            end_offset: node.location.end_offset,
            replacement: "expect(#{expect_arg.location.slice}).#{expectation_method}"
          )
        end

        def expectation_method_for(node)
          return unless expect_be_nil_call?(node)

          { to: "must_be_nil", not_to: "wont_be_nil" }[node.name]
        end

        def expect_be_nil_call?(node)
          %i[to not_to].include?(node.name) &&
            expect_call?(node.receiver) &&
            be_nil_matcher?(be_nil_matcher(node))
        end

        def expect_call?(node)
          node.is_a?(Prism::CallNode) &&
            node.name == :expect &&
            node.receiver.nil? &&
            node.arguments&.arguments&.length == 1
        end

        def be_nil_matcher?(node)
          node.is_a?(Prism::CallNode) &&
            node.name == :be_nil &&
            node.receiver.nil? &&
            (node.arguments.nil? || node.arguments.arguments.empty?)
        end

        def be_nil_matcher(node)
          node.arguments&.arguments&.first
        end
      end
    end
  end
end
