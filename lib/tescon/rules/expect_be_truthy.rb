# frozen_string_literal: true

require "prism"

module Tescon
  module Rules
    # Finds RSpec be_truthy / be_falsey expectations that can be translated to minitest assertions.
    class ExpectBeTruthy
      RULE_NAME = "expect_be_truthy"
      MATCHERS = {
        be_truthy: { to: "must_equal true", not_to: "wont_equal true" },
        be_falsey: { to: "must_equal false", not_to: "wont_equal false" }
      }.freeze

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
          matcher_config = matcher_config_for(node)
          return unless matcher_config

          expect_arg = node.receiver.arguments.arguments.first
          expectation_method = matcher_config[node.name]

          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert RSpec #{matcher_config[:matcher]} expectation to minitest assertion",
            start_offset: node.location.start_offset,
            end_offset: node.location.end_offset,
            replacement: "expect(#{expect_arg.location.slice}).#{expectation_method}"
          )
        end

        def matcher_config_for(node)
          return unless %i[to not_to].include?(node.name)
          return unless expect_call?(node.receiver)

          matcher_node = predicate_matcher(node)
          return unless predicate_matcher?(matcher_node)

          matcher = matcher_node.name
          methods = MATCHERS[matcher]
          return unless methods

          methods.merge(matcher: matcher)
        end

        def expect_call?(node)
          node.is_a?(Prism::CallNode) &&
            node.name == :expect &&
            node.receiver.nil? &&
            node.arguments&.arguments&.length == 1
        end

        def predicate_matcher?(node)
          node.is_a?(Prism::CallNode) &&
            MATCHERS.key?(node.name) &&
            node.receiver.nil? &&
            (node.arguments.nil? || node.arguments.arguments.empty?)
        end

        def predicate_matcher(node)
          node.arguments&.arguments&.first
        end
      end
    end
  end
end
