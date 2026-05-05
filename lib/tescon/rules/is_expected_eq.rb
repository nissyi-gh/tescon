# frozen_string_literal: true

require "prism"

module Tescon
  module Rules
    # Converts RSpec one-liner is_expected eq matchers to minitest assertions on subject/let.
    class IsExpectedEq
      RULE_NAME = "is_expected_eq"

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
          @subject_method = :subject
          @subject_stack = []
          super()
        end

        def visit_call_node(node)
          pushed_frame = false
          if describe_like?(node) && node.block
            @subject_stack.push(@subject_method)
            pushed_frame = true
          end

          capture_subject_alias(node)

          finding = finding_for(node)
          @findings << finding if finding

          super
        ensure
          @subject_method = @subject_stack.pop if pushed_frame
        end

        private

        def finding_for(node)
          expectation_method = expectation_method_for(node)
          return unless expectation_method

          eq_arg = eq_matcher(node).arguments.arguments.first
          name = @subject_method.to_s

          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert RSpec is_expected eq to minitest must_equal/wont_equal",
            start_offset: node.receiver.location.start_offset,
            end_offset: node.location.end_offset,
            replacement: "#{name}.#{expectation_method} #{eq_arg.location.slice}"
          )
        end

        def expectation_method_for(node)
          return unless is_expected_eq_call?(node)

          { to: "must_equal", not_to: "wont_equal" }[node.name]
        end

        def is_expected_eq_call?(node)
          %i[to not_to].include?(node.name) &&
            is_expected_call?(node.receiver) &&
            eq_matcher?(eq_matcher(node))
        end

        def is_expected_call?(node)
          node.is_a?(Prism::CallNode) &&
            node.name == :is_expected &&
            node.receiver.nil? &&
            (node.arguments.nil? || node.arguments.arguments.empty?)
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

        def describe_like?(node)
          return false unless node.block

          case node.name
          when :context
            node.receiver.nil?
          when :describe
            node.receiver.nil? || rspec_describe_receiver?(node.receiver)
          else
            false
          end
        end

        def rspec_describe_receiver?(receiver)
          receiver.is_a?(Prism::ConstantReadNode) && receiver.name == :RSpec
        end

        def capture_subject_alias(node)
          return unless subject_declaration?(node)

          if named_subject?(node)
            sym = node.arguments.arguments.first
            @subject_method = sym.unescaped.to_sym if sym.is_a?(Prism::SymbolNode)
          elsif unnamed_subject?(node)
            @subject_method = :subject
          end
        end

        def subject_declaration?(node)
          node.name == :subject &&
            node.receiver.nil? &&
            node.block &&
            node.message_loc
        end

        def named_subject?(node)
          arguments = node.arguments&.arguments

          arguments&.length == 1 && arguments.first.is_a?(Prism::SymbolNode)
        end

        def unnamed_subject?(node)
          node.arguments.nil?
        end
      end
    end
  end
end
