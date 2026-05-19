# frozen_string_literal: true

require "prism"

module Tescon
  module Notices
    # Flags before(:all) / after(:all) for manual review after migration.
    class BeforeAll
      RULE_NAME = "before_all"
      HOOKS = %i[before after].freeze
      def analyze(source_file)
        Visitor.notices(source_file)
      end

      class Visitor < Prism::Visitor
        def self.notices(source_file)
          new(source_file).tap { |visitor| visitor.visit(Prism.parse(source_file.source).value) }.notices
        end

        attr_reader :notices

        def initialize(source_file)
          @source_file = source_file
          @notices = []
          super()
        end

        def visit_call_node(node)
          notice = notice_for(node)
          @notices << notice if notice

          super
        end

        private

        attr_reader :source_file

        def notice_for(node)
          return unless all_hook?(node)

          Notice.new(
            rule_name: RULE_NAME,
            line: line_for(node),
            severity: :review,
            message: "#{node.name}(:all) left unchanged; verify DB isolation and transactional fixtures"
          )
        end

        def all_hook?(node)
          HOOKS.include?(node.name) &&
            node.receiver.nil? &&
            node.block &&
            symbol_argument(node)&.unescaped == "all"
        end

        def symbol_argument(node)
          return unless node.arguments&.arguments&.length == 1

          argument = node.arguments.arguments.first
          argument if argument.is_a?(Prism::SymbolNode)
        end

        def line_for(node)
          source_file.source.byteslice(0, node.location.start_offset).count("\n") + 1
        end
      end
    end
  end
end
