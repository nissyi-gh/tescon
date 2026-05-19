# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::ExpectInclude do
  def convert(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    analysis_result = Tescon::AnalysisResult.new(
      source_file: source_file,
      findings: Tescon::Rules::ExpectInclude.new.analyze(source_file)
    )

    Tescon::Rewriter.new.rewrite(analysis_result).converted_source
  end

  it "converts expect(...).to include(...) to expect(...).must_include" do
    source = <<~RUBY
      expect(user.roles).to include("admin")
    RUBY

    expected = <<~RUBY
      expect(user.roles).must_include "admin"
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts expect(...).not_to include(...) to expect(...).wont_include" do
    source = <<~RUBY
      expect(user.roles).not_to include("guest")
    RUBY

    expected = <<~RUBY
      expect(user.roles).wont_include "guest"
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "does not convert expect syntax inside strings" do
    source = <<~RUBY
      message = 'expect(user.roles).to include("admin")'
    RUBY

    expect(convert(source)).must_equal source
  end
end
