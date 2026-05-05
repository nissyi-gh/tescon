# frozen_string_literal: true

require_relative "test_helper"

describe Tescon::Rewriter do
  it "applies findings from the end of the source" do
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: "RSpec.describe User\n")
    finding = Tescon::Finding.new(
      rule_name: "rspec_describe",
      message: "Convert RSpec.describe to minitest describe",
      start_offset: 0,
      end_offset: 14,
      replacement: "describe"
    )
    analysis_result = Tescon::AnalysisResult.new(source_file: source_file, findings: [finding])

    result = Tescon::Rewriter.new.rewrite(analysis_result)

    expect(result.converted_source).must_equal "describe User\n"
    expect(result.changes).must_equal [finding]
  end
end
