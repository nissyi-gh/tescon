# frozen_string_literal: true

module Tescon
  module Trace
    RecordSnapshot = Data.define(:model, :table, :id, :attributes, :classification)
    FactoryCall = Data.define(:strategy, :factory_name, :caller, :traits, :overrides, :records) do
      def initialize(strategy:, factory_name:, caller:, traits: [], overrides: {}, records: [])
        super
      end
    end
    ExampleTrace = Data.define(:id, :file, :line, :description, :factory_calls, :side_effect_records) do
      def initialize(id:, file:, line:, description:, factory_calls: [], side_effect_records: [])
        super
      end
    end
  end
end
