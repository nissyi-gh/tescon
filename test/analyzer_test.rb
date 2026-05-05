# frozen_string_literal: true

require_relative "test_helper"

describe Tescon::Analyzer do
  it "returns findings without rewriting the source" do
    source_file = Tescon::SourceFile.new(
      path: "user_spec.rb",
      source: %(expect(user.name).to eq("Alice")\n)
    )

    result = Tescon::Analyzer.new.analyze(source_file)

    expect(result.source_file).must_equal source_file
    expect(result.findings.map(&:rule_name)).must_include "expect_eq"
    expect(source_file.source).must_equal %(expect(user.name).to eq("Alice")\n)
  end
end
