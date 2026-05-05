# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::ExpectEq do
  def convert(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    analysis_result = Tescon::AnalysisResult.new(
      source_file: source_file,
      findings: Tescon::Rules::ExpectEq.new.analyze(source_file)
    )

    Tescon::Rewriter.new.rewrite(analysis_result).converted_source
  end

  it "converts expect(...).to eq(...) to expect(...).must_equal" do
    source = <<~RUBY
      expect(user.name).to eq("Alice")
    RUBY

    expected = <<~RUBY
      expect(user.name).must_equal "Alice"
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts nested expressions" do
    source = <<~RUBY
      expect(user.names.fetch(0)).to eq(default_names.fetch(:first))
    RUBY

    expected = <<~RUBY
      expect(user.names.fetch(0)).must_equal default_names.fetch(:first)
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "does not convert expect syntax inside strings" do
    source = <<~RUBY
      message = 'expect(user.name).to eq("Alice")'
    RUBY

    expect(convert(source)).must_equal source
  end

  it "converts expect(...).not_to eq(...) to expect(...).wont_equal" do
    source = <<~RUBY
      expect(user.name).not_to eq("Alice")
    RUBY

    expected = <<~RUBY
      expect(user.name).wont_equal "Alice"
    RUBY

    expect(convert(source)).must_equal expected
  end
end
