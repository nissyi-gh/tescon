# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::ExpectMatch do
  def convert(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    analysis_result = Tescon::AnalysisResult.new(
      source_file: source_file,
      findings: Tescon::Rules::ExpectMatch.new.analyze(source_file)
    )

    Tescon::Rewriter.new.rewrite(analysis_result).converted_source
  end

  it "converts expect(...).to match(...) to expect(...).must_match" do
    source = <<~RUBY
      expect(user.email).to match(/@example\\.com\\z/)
    RUBY

    expected = <<~RUBY
      expect(user.email).must_match /@example\\.com\\z/
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts expect(...).not_to match(...) to expect(...).wont_match" do
    source = <<~RUBY
      expect(user.email).not_to match(/invalid/)
    RUBY

    expected = <<~RUBY
      expect(user.email).wont_match /invalid/
    RUBY

    expect(convert(source)).must_equal expected
  end
end
