# frozen_string_literal: true

require "prism"

module Tescon
  module Rules
    # Finds FactoryBot calls that can become fixture migration hints.
    class FactoryBot
      STRATEGIES = %i[build create build_stubbed].freeze
      EXAMPLE_DSL = %i[describe context it specify].freeze

      def analyze(source_file)
        Visitor.usages(source_file)
      end

      class Visitor < Prism::Visitor
        def self.usages(source_file)
          new(source_file).tap { |visitor| visitor.visit(Prism.parse(source_file.source).value) }.usages
        end

        attr_reader :usages

        def initialize(source_file)
          @source_file = source_file
          @context_stack = []
          @usages = []
          super()
        end

        def visit_call_node(node)
          pushed_context = false
          if example_context?(node)
            @context_stack.push(context_label(node))
            pushed_context = true
          end

          usage = usage_for(node)
          @usages << usage if usage

          super
        ensure
          @context_stack.pop if pushed_context
        end

        private

        attr_reader :source_file

        def usage_for(node)
          return unless factory_bot_call?(node)

          arguments = node.arguments&.arguments
          factory_name = factory_name_for(arguments&.first)
          return unless factory_name

          FactoryBotUsage.new(
            source_file: source_file,
            strategy: node.name,
            factory_name: factory_name,
            attributes: attributes_for(arguments.drop(1)),
            context: @context_stack.compact,
            line: line_for(node)
          )
        end

        def factory_bot_call?(node)
          STRATEGIES.include?(node.name) &&
            (node.receiver.nil? || factory_bot_receiver?(node.receiver))
        end

        def factory_bot_receiver?(node)
          node.is_a?(Prism::ConstantReadNode) && node.name == :FactoryBot
        end

        def factory_name_for(node)
          return unless node.is_a?(Prism::SymbolNode)

          node.unescaped
        end

        def attributes_for(arguments)
          hash = arguments.find { |argument| hash_like?(argument) }
          return [] unless hash

          hash.elements.filter_map do |element|
            next unless element.is_a?(Prism::AssocNode)

            attribute_for(element)
          end
        end

        def hash_like?(node)
          node.is_a?(Prism::HashNode) || node.is_a?(Prism::KeywordHashNode)
        end

        def attribute_for(node)
          name = key_name_for(node.key)
          return unless name

          literal, value = literal_value_for(node.value)
          FactoryBotAttribute.new(
            name: name,
            value: value,
            source: node.value.location.slice,
            literal: literal
          )
        end

        def key_name_for(node)
          case node
          when Prism::SymbolNode
            node.unescaped
          when Prism::StringNode
            node.unescaped
          end
        end

        def literal_value_for(node)
          case node
          when Prism::StringNode
            [true, node.unescaped]
          when Prism::IntegerNode, Prism::FloatNode
            [true, node.value]
          when Prism::TrueNode
            [true, true]
          when Prism::FalseNode
            [true, false]
          when Prism::NilNode
            [true, nil]
          else
            [false, nil]
          end
        end

        def example_context?(node)
          EXAMPLE_DSL.include?(node.name) &&
            example_receiver?(node) &&
            node.block
        end

        def example_receiver?(node)
          return true if node.receiver.nil?

          node.name == :describe && rspec_receiver?(node.receiver)
        end

        def rspec_receiver?(node)
          node.is_a?(Prism::ConstantReadNode) && node.name == :RSpec
        end

        def context_label(node)
          first_argument = node.arguments&.arguments&.first

          case first_argument
          when Prism::StringNode, Prism::SymbolNode
            first_argument.unescaped
          when Prism::ConstantReadNode
            first_argument.name.to_s
          end
        end

        def line_for(node)
          source_file.source.byteslice(0, node.location.start_offset).count("\n") + 1
        end
      end
    end
  end
end
