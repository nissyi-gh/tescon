# frozen_string_literal: true

require "prism"

module Tescon
  module Rules
    # Converts RSpec before(:each) / after(:each) to minitest-spec before / after.
    class BeforeEach
      RULE_NAME = "before_each"
      HOOKS = %i[before after].freeze

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
          return unless each_hook?(node)

          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert RSpec #{node.name}(:each) to minitest-spec #{node.name}",
            start_offset: node.message_loc.start_offset,
            end_offset: node.closing_loc.end_offset,
            replacement: node.name.to_s
          )
        end

        def each_hook?(node)
          HOOKS.include?(node.name) &&
            node.receiver.nil? &&
            node.block &&
            node.message_loc &&
            node.closing_loc &&
            node.arguments&.arguments&.length == 1 &&
            node.arguments.arguments.first.is_a?(Prism::SymbolNode) &&
            node.arguments.arguments.first.unescaped == "each"
        end
      end
    end
  end
end
