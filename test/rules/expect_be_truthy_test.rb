# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::ExpectBeTruthy do
  def convert(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    analysis_result = Tescon::AnalysisResult.new(
      source_file: source_file,
      findings: Tescon::Rules::ExpectBeTruthy.new.analyze(source_file)
    )

    Tescon::Rewriter.new.rewrite(analysis_result).converted_source
  end

  it "converts expect(...).to be_truthy to expect(...).must_equal true" do
    source = <<~RUBY
      expect(user.active?).to be_truthy
    RUBY

    expected = <<~RUBY
      expect(user.active?).must_equal true
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts expect(...).to be_falsey to expect(...).must_equal false" do
    source = <<~RUBY
      expect(user.name).to be_falsey
    RUBY

    expected = <<~RUBY
      expect(user.name).must_equal false
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts expect(...).not_to be_truthy to expect(...).wont_equal true" do
    source = <<~RUBY
      expect(user.active?).not_to be_truthy
    RUBY

    expected = <<~RUBY
      expect(user.active?).wont_equal true
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "does not convert expect syntax inside strings" do
    source = <<~RUBY
      message = 'expect(user).to be_truthy'
    RUBY

    expect(convert(source)).must_equal source
  end
end
