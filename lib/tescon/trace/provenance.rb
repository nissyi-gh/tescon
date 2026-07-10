# frozen_string_literal: true

module Tescon
  module Trace
    RecordSnapshot = Data.define(:model, :table, :id, :attributes, :classification, :caller, :via, :links) do
      def initialize(model:, table:, id:, attributes:, classification:, caller: nil, via: nil, links: [])
        super
      end
    end

    FactoryCall = Data.define(:call_id, :parent_call_id, :strategy, :factory_name, :caller, :traits, :overrides, :count,
                              :records) do
      def initialize(call_id:, strategy:, factory_name:, caller:, parent_call_id: nil, traits: [], overrides: {},
                     count: nil, records: [])
        super
      end
    end

    ExampleTrace = Data.define(:id, :file, :line, :description, :full_description, :factory_calls,
                               :side_effect_records) do
      def initialize(id:, file:, line:, description:, full_description: nil, factory_calls: [], side_effect_records: [])
        super
      end
    end
  end
end
