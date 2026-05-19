# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::BeforeEach do
  def convert(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    analysis_result = Tescon::AnalysisResult.new(
      source_file: source_file,
      findings: Tescon::Rules::BeforeEach.new.analyze(source_file)
    )

    Tescon::Rewriter.new.rewrite(analysis_result).converted_source
  end

  it "converts before(:each) to before" do
    source = <<~RUBY
      before(:each) do
        @user = User.new
      end
    RUBY

    expected = <<~RUBY
      before do
        @user = User.new
      end
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts after(:each) to after" do
    source = <<~RUBY
      after(:each) do
        @user = nil
      end
    RUBY

    expected = <<~RUBY
      after do
        @user = nil
      end
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "does not convert bare before blocks" do
    source = <<~RUBY
      before do
        @user = User.new
      end
    RUBY

    expect(convert(source)).must_equal source
  end

  it "does not convert before(:all)" do
    source = <<~RUBY
      before(:all) do
        @user = User.new
      end
    RUBY

    expect(convert(source)).must_equal source
  end
end
