# frozen_string_literal: true

module Tescon
  module Rules
    module DescribeHelpers
      module_function

      def model_type?(node)
        keyword_hash_arguments(node).any? do |hash|
          hash.elements.any? { |assoc| type_model_assoc?(assoc) }
        end
      end

      def constant_subject?(node)
        arg = node.arguments&.arguments&.first
        arg.is_a?(Prism::ConstantReadNode) || arg.is_a?(Prism::ConstantPathNode)
      end

      def keyword_hash_arguments(node)
        node.arguments&.arguments&.grep(Prism::KeywordHashNode) || []
      end

      def type_model_assoc?(assoc)
        return false unless assoc.is_a?(Prism::AssocNode)

        key = assoc.key
        value = assoc.value
        key.is_a?(Prism::SymbolNode) && key.unescaped == "type" &&
          value.is_a?(Prism::SymbolNode) && value.unescaped == "model"
      end
    end
  end
end
