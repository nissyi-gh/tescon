# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::LetBang do
  def convert(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    analysis_result = Tescon::AnalysisResult.new(
      source_file: source_file,
      findings: Tescon::Rules::LetBang.new.analyze(source_file)
    )

    Tescon::Rewriter.new.rewrite(analysis_result).converted_source
  end

  it "converts let! to let with a before hook" do
    source = <<~RUBY
      describe User do
        let!(:user) { User.new(name: "Alice") }
      end
    RUBY

    expected = <<~RUBY
      describe User do
        let(:user) { User.new(name: "Alice") }
        before { user }
      end
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "preserves indentation" do
    source = <<~RUBY
      describe User do
        context "with a user" do
          let!(:user) { User.new }
        end
      end
    RUBY

    result = convert(source)
    expect(result).must_include("    let(:user) { User.new }\n    before { user }")
  end

  it "does not convert let" do
    source = <<~RUBY
      let(:user) { User.new }
    RUBY

    expect(convert(source)).must_equal source
  end
end
