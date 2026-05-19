# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::ExpectBePresent do
  def convert(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    analysis_result = Tescon::AnalysisResult.new(
      source_file: source_file,
      findings: Tescon::Rules::ExpectBePresent.new.analyze(source_file)
    )

    Tescon::Rewriter.new.rewrite(analysis_result).converted_source
  end

  it "converts expect(...).to be_present to expect(...).must_be :present?" do
    source = <<~RUBY
      expect(user.name).to be_present
    RUBY

    expected = <<~RUBY
      expect(user.name).must_be :present?
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts expect(...).to be_blank to expect(...).must_be :blank?" do
    source = <<~RUBY
      expect(user.name).to be_blank
    RUBY

    expected = <<~RUBY
      expect(user.name).must_be :blank?
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts expect(...).not_to be_empty to expect(...).wont_be :empty?" do
    source = <<~RUBY
      expect(user.roles).not_to be_empty
    RUBY

    expected = <<~RUBY
      expect(user.roles).wont_be :empty?
    RUBY

    expect(convert(source)).must_equal expected
  end
end
