# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::ExampleDsl do
  def convert(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    analysis_result = Tescon::AnalysisResult.new(
      source_file: source_file,
      findings: Tescon::Rules::ExampleDsl.new.analyze(source_file)
    )

    Tescon::Rewriter.new.rewrite(analysis_result).converted_source
  end

  it "converts context to describe" do
    source = <<~RUBY
      context "when active" do
      end
    RUBY

    expected = <<~RUBY
      describe "when active" do
      end
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts specify to it" do
    source = <<~RUBY
      specify "has a name" do
      end
    RUBY

    expected = <<~RUBY
      it "has a name" do
      end
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "does not convert example DSL inside strings" do
    source = <<~RUBY
      message = 'context "when active" do'
      other = 'specify "works" do'
    RUBY

    expect(convert(source)).must_equal source
  end

  it "does not convert receiver method calls" do
    source = <<~RUBY
      helper.context "value"
      helper.specify "value"
    RUBY

    expect(convert(source)).must_equal source
  end
end
