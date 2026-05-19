# frozen_string_literal: true

require_relative "test_helper"

describe Tescon::Annotator do
  def annotate(source, notices)
    Tescon::Annotator.new.apply(source, notices).source
  end

  def notice(rule_name:, line:, severity: :review, message: "example message")
    Tescon::Notice.new(rule_name: rule_name, line: line, severity: severity, message: message)
  end

  it "inserts a review comment above the target line" do
    source = <<~RUBY
      describe User do
        before(:all) do
          @user = User.new
        end
      end
    RUBY

    notices = [
      notice(
        rule_name: "before_all",
        line: 2,
        message: "before(:all) left unchanged; verify DB isolation and transactional fixtures"
      )
    ]

    expected = <<~RUBY
      describe User do
        # tescon: review — [before_all] before(:all) left unchanged; verify DB isolation and transactional fixtures
        before(:all) do
          @user = User.new
        end
      end
    RUBY

    expect(annotate(source, notices)).must_equal expected
  end

  it "preserves indentation on the comment line" do
    source = <<~RUBY
      describe User do
        before(:all) do
        end
      end
    RUBY

    notices = [notice(rule_name: "before_all", line: 2, message: "review me")]

    result = annotate(source, notices)
    expect(result).must_include("  # tescon: review — [before_all] review me\n  before(:all) do")
  end

  it "does not insert a duplicate comment on the second run" do
    source = <<~RUBY
      before(:all) do
      end
    RUBY

    notices = [notice(rule_name: "before_all", line: 1, message: "review me")]
    first = annotate(source, notices)
    second = annotate(first, [notice(rule_name: "before_all", line: 2, message: "review me")])

    expect(second).must_equal first
    expect(second.scan("# tescon:").length).must_equal 1
  end

  it "stays idempotent when notices are re-detected from annotated source" do
    source = <<~RUBY
      before(:all) do
      end
    RUBY

    first = annotate_with_analysis(source)
    second = annotate_with_analysis(first)

    expect(second).must_equal first
    expect(second.scan("# tescon:").length).must_equal 1
  end

  def annotate_with_analysis(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    analysis = Tescon::Analyzer.new.analyze(source_file)
    Tescon::Annotator.new.apply(source, analysis.notices).source
  end
end
