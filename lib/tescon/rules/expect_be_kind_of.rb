# frozen_string_literal: true

require "prism"

module Tescon
  module Rules
    # Finds RSpec be_a / be_kind_of expectations for minitest type assertions.
    class ExpectBeKindOf
      RULE_NAME = "expect_be_kind_of"
      MATCHERS = {
        be_a: { to: "must_be_instance_of", not_to: "wont_be_instance_of" },
        be_an: { to: "must_be_instance_of", not_to: "wont_be_instance_of" },
        be_kind_of: { to: "must_be_kind_of", not_to: "wont_be_kind_of" },
        be_a_kind_of: { to: "must_be_kind_of", not_to: "wont_be_kind_of" }
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
          type_arg = matcher(node).arguments.arguments.first

          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert RSpec #{matcher_config[:matcher]} expectation to minitest type assertion",
            start_offset: node.location.start_offset,
            end_offset: node.location.end_offset,
            replacement: "expect(#{expect_arg.location.slice}).#{matcher_config[node.name]} #{type_arg.location.slice}"
          )
        end

        def matcher_config_for(node)
          return unless %i[to not_to].include?(node.name)
          return unless expect_call?(node.receiver)

          matcher_node = matcher(node)
          return unless type_matcher?(matcher_node)

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

        def type_matcher?(node)
          node.is_a?(Prism::CallNode) &&
            MATCHERS.key?(node.name) &&
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
