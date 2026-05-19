# frozen_string_literal: true

require_relative "rules/before_each"
require_relative "rules/example_dsl"
require_relative "rules/expect_be_nil"
require_relative "rules/expect_be_truthy"
require_relative "rules/expect_eq"
require_relative "rules/factory_bot"
require_relative "rules/is_expected_eq"
require_relative "rules/rspec_describe"
require_relative "rules/subject"

module Tescon
  SourceFile = Data.define(:path, :source)
  Finding = Data.define(:rule_name, :message, :start_offset, :end_offset, :replacement)
  FactoryBotAttribute = Data.define(:name, :value, :source, :literal)
  FactoryBotUsage = Data.define(:source_file, :strategy, :factory_name, :attributes, :context, :line)
  AnalysisResult = Data.define(:source_file, :findings, :factory_usages) do
    def initialize(source_file:, findings:, factory_usages: [])
      super
    end
  end

  # Runs conversion rules and returns findings without modifying source.
  class Analyzer
    DEFAULT_RULES = [
      Rules::RspecDescribe.new,
      Rules::BeforeEach.new,
      Rules::ExampleDsl.new,
      Rules::Subject.new,
      Rules::ExpectBeNil.new,
      Rules::ExpectBeTruthy.new,
      Rules::ExpectEq.new,
      Rules::IsExpectedEq.new
    ].freeze
    DEFAULT_FACTORY_RULES = [
      Rules::FactoryBot.new
    ].freeze

    def initialize(rules: DEFAULT_RULES, factory_rules: DEFAULT_FACTORY_RULES)
      @rules = rules
      @factory_rules = factory_rules
    end

    def analyze(source_file)
      AnalysisResult.new(
        source_file: source_file,
        findings: rules.flat_map { |rule| rule.analyze(source_file) },
        factory_usages: factory_rules.flat_map { |rule| rule.analyze(source_file) }
      )
    end

    private

    attr_reader :rules, :factory_rules
  end
end
