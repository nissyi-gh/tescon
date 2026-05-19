# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::ExpectBeNil do
  def convert(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    analysis_result = Tescon::AnalysisResult.new(
      source_file: source_file,
      findings: Tescon::Rules::ExpectBeNil.new.analyze(source_file)
    )

    Tescon::Rewriter.new.rewrite(analysis_result).converted_source
  end

  it "converts expect(...).to be_nil to expect(...).must_be_nil" do
    source = <<~RUBY
      expect(user.name).to be_nil
    RUBY

    expected = <<~RUBY
      expect(user.name).must_be_nil
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts expect(...).not_to be_nil to expect(...).wont_be_nil" do
    source = <<~RUBY
      expect(user.name).not_to be_nil
    RUBY

    expected = <<~RUBY
      expect(user.name).wont_be_nil
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "does not convert expect syntax inside strings" do
    source = <<~RUBY
      message = 'expect(user.name).to be_nil'
    RUBY

    expect(convert(source)).must_equal source
  end
end
