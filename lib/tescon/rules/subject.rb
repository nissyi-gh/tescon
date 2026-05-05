# frozen_string_literal: true

require "prism"

module Tescon
  module Rules
    # Converts RSpec subject declarations to minitest-spec let declarations.
    class Subject
      RULE_NAME = "subject"

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
          return unless subject_call?(node)

          if named_subject?(node)
            named_subject_finding(node)
          elsif unnamed_subject?(node)
            unnamed_subject_finding(node)
          end
        end

        def subject_call?(node)
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

        def named_subject_finding(node)
          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert named RSpec subject to minitest let",
            start_offset: node.message_loc.start_offset,
            end_offset: node.message_loc.end_offset,
            replacement: "let"
          )
        end

        def unnamed_subject_finding(node)
          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert unnamed RSpec subject to minitest let",
            start_offset: node.message_loc.start_offset,
            end_offset: node.message_loc.end_offset,
            replacement: "let(:subject)"
          )
        end
      end
    end
  end
end
