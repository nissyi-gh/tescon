# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::ExpectBeValid do
  def convert(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    analysis_result = Tescon::AnalysisResult.new(
      source_file: source_file,
      findings: Tescon::Rules::ExpectBeValid.new.analyze(source_file)
    )

    Tescon::Rewriter.new.rewrite(analysis_result).converted_source
  end

  it "converts expect(...).to be_valid to expect(...).must_be :valid?" do
    source = <<~RUBY
      expect(user).to be_valid
    RUBY

    expected = <<~RUBY
      expect(user).must_be :valid?
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts expect(...).to be_invalid to expect(...).must_be :invalid?" do
    source = <<~RUBY
      expect(user).to be_invalid
    RUBY

    expected = <<~RUBY
      expect(user).must_be :invalid?
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts expect(...).not_to be_valid to expect(...).wont_be :valid?" do
    source = <<~RUBY
      expect(user).not_to be_valid
    RUBY

    expected = <<~RUBY
      expect(user).wont_be :valid?
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "does not convert expect syntax inside strings" do
    source = <<~RUBY
      message = 'expect(user).to be_valid'
    RUBY

    expect(convert(source)).must_equal source
  end
end
