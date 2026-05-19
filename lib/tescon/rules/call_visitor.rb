# frozen_string_literal: true

require "prism"

module Tescon
  module Rules
    # Shared Prism visitor that collects findings from call nodes.
    # Subclasses must implement #finding_for.
    class CallVisitor < Prism::Visitor
      def self.findings(source_file)
        new(source_file).tap { |visitor| visitor.visit(Prism.parse(source_file.source).value) }.findings
      end

      attr_reader :findings, :source_file

      def initialize(source_file = nil)
        @source_file = source_file
        @findings = []
        super()
      end

      def visit_call_node(node)
        finding = finding_for(node)
        @findings << finding if finding

        super
      end
    end
  end
end
