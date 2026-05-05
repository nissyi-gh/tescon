# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::Subject do
  def convert(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    analysis_result = Tescon::AnalysisResult.new(
      source_file: source_file,
      findings: Tescon::Rules::Subject.new.analyze(source_file)
    )

    Tescon::Rewriter.new.rewrite(analysis_result).converted_source
  end

  it "converts named subject to let" do
    source = <<~RUBY
      subject(:user) { User.new }
    RUBY

    expected = <<~RUBY
      let(:user) { User.new }
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts unnamed subject to let(:subject)" do
    source = <<~RUBY
      subject { User.new }
    RUBY

    expected = <<~RUBY
      let(:subject) { User.new }
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts multiline subject declarations" do
    source = <<~RUBY
      subject(:user) do
        User.new
      end

      subject do
        User.new
      end
    RUBY

    expected = <<~RUBY
      let(:user) do
        User.new
      end

      let(:subject) do
        User.new
      end
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "does not convert subject inside strings" do
    source = <<~RUBY
      message = "subject(:user) { User.new }"
    RUBY

    expect(convert(source)).must_equal source
  end

  it "does not convert receiver method calls" do
    source = <<~RUBY
      helper.subject(:user) { User.new }
    RUBY

    expect(convert(source)).must_equal source
  end
end
