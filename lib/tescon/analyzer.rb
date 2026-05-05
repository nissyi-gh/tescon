# frozen_string_literal: true

require_relative "rules/example_dsl"
require_relative "rules/expect_eq"
require_relative "rules/is_expected_eq"
require_relative "rules/rspec_describe"
require_relative "rules/subject"

module Tescon
  SourceFile = Data.define(:path, :source)
  Finding = Data.define(:rule_name, :message, :start_offset, :end_offset, :replacement)
  AnalysisResult = Data.define(:source_file, :findings)

  # Runs conversion rules and returns findings without modifying source.
  class Analyzer
    DEFAULT_RULES = [
      Rules::RspecDescribe.new,
      Rules::ExampleDsl.new,
      Rules::Subject.new,
      Rules::ExpectEq.new,
      Rules::IsExpectedEq.new
    ].freeze

    def initialize(rules: DEFAULT_RULES)
      @rules = rules
    end

    def analyze(source_file)
      AnalysisResult.new(
        source_file: source_file,
        findings: rules.flat_map { |rule| rule.analyze(source_file) }
      )
    end

    private

    attr_reader :rules
  end
end
