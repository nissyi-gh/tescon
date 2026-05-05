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

  it "splices prism byte offsets in UTF-8 sources (not character indices)" do
    body = ("あ" * 950).dup # 950 chars, 2850 bytes; byte ranges can exceed character length
    source_file = Tescon::SourceFile.new(path: "wide_spec.rb", source: "#{body}\n")
    finding = Tescon::Finding.new(
      rule_name: "rspec_describe",
      message: "",
      start_offset: 2826,
      end_offset: 2844,
      replacement: ""
    )
    analysis_result = Tescon::AnalysisResult.new(source_file: source_file, findings: [finding])

    result = Tescon::Rewriter.new.rewrite(analysis_result)

    expect(result.converted_source.encoding).must_equal Encoding::UTF_8
    expect(result.converted_source.valid_encoding?).must_equal true
    expect(result.converted_source.bytesize).must_equal(source_file.source.bytesize - 18)
    expect(result.converted_source.length).must_equal(950 - 6 + 1)
  end
end
