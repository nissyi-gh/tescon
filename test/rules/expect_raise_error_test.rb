# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::ExpectRaiseError do
  def convert(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    analysis_result = Tescon::AnalysisResult.new(
      source_file: source_file,
      findings: Tescon::Rules::ExpectRaiseError.new.analyze(source_file)
    )

    Tescon::Rewriter.new.rewrite(analysis_result).converted_source
  end

  it "converts expect { }.to raise_error(Error) to assert_raises" do
    source = <<~RUBY
      expect { user.save! }.to raise_error(ActiveRecord::RecordInvalid)
    RUBY

    expected = <<~RUBY
      assert_raises(ActiveRecord::RecordInvalid) { user.save! }
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts raise_error with a message argument" do
    source = <<~RUBY
      expect { user.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed, "Failed")
    RUBY

    expected = <<~RUBY
      assert_raises(ActiveRecord::RecordNotDestroyed, "Failed") { user.destroy! }
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "does not convert value expect(...).to raise_error" do
    source = <<~RUBY
      expect(error).to raise_error
    RUBY

    expect(convert(source)).must_equal source
  end
end
