# frozen_string_literal: true

require_relative "base"
require_relative "call_visitor"

module Tescon
  module Rules
    # Shared implementation for expect(...).to matcher expectations.
    class ExpectMatcher < Base
      def analyze(source_file)
        Visitor.findings(source_file, self.class)
      end

      class << self
        attr_reader :rule_name, :matchers, :message, :requires_argument

        def matcher_config(rule_name:, matchers:, message:, requires_argument: false)
          @rule_name = rule_name
          @matchers = matchers
          @message = message
          @requires_argument = requires_argument
        end
      end

      class Visitor < CallVisitor
        def self.findings(source_file, rule_class)
          new(source_file, rule_class).tap { |visitor| visitor.visit(Prism.parse(source_file.source).value) }.findings
        end

        def initialize(source_file, rule_class)
          @rule_class = rule_class
          super(source_file)
        end

        private

        attr_reader :rule_class

        def finding_for(node)
          config = matcher_config_for(node)
          return unless config

          expect_arg = node.receiver.arguments.arguments.first
          replacement = replacement_for(node, config, expect_arg, matcher(node))

          Finding.new(
            rule_name: rule_class.rule_name,
            message: message_for(config),
            start_offset: node.location.start_offset,
            end_offset: node.location.end_offset,
            replacement: replacement
          )
        end

        def replacement_for(node, config, expect_arg, matcher_node)
          base = "expect(#{expect_arg.location.slice}).#{config[node.name]}"

          return base unless rule_class.requires_argument

          matcher_arg = matcher_node.arguments.arguments.first
          "#{base} #{matcher_arg.location.slice}"
        end

        def message_for(config)
          format(rule_class.message, matcher: config[:matcher])
        end

        def matcher_config_for(node)
          return unless %i[to not_to].include?(node.name)
          return unless expect_call?(node.receiver)

          matcher_node = matcher(node)
          return unless matcher_node
          return unless matcher_matches?(matcher_node)

          matcher = matcher_node.name
          methods = rule_class.matchers[matcher]
          return unless methods

          methods.merge(matcher: matcher)
        end

        def matcher_matches?(node)
          return false unless node.is_a?(Prism::CallNode)
          return false unless rule_class.matchers.key?(node.name)
          return false unless node.receiver.nil?

          if rule_class.requires_argument
            node.arguments&.arguments&.length == 1
          else
            node.arguments.nil? || node.arguments.arguments.empty?
          end
        end

        def expect_call?(node)
          node.is_a?(Prism::CallNode) &&
            node.name == :expect &&
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
