# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::ExpectBeKindOf do
  def convert(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    analysis_result = Tescon::AnalysisResult.new(
      source_file: source_file,
      findings: Tescon::Rules::ExpectBeKindOf.new.analyze(source_file)
    )

    Tescon::Rewriter.new.rewrite(analysis_result).converted_source
  end

  it "converts expect(...).to be_a(Class) to expect(...).must_be_instance_of" do
    source = <<~RUBY
      expect(user).to be_a(User)
    RUBY

    expected = <<~RUBY
      expect(user).must_be_instance_of User
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts expect(...).to be_an(Class) to expect(...).must_be_instance_of" do
    source = <<~RUBY
      expect(user.id).to be_an(Integer)
    RUBY

    expected = <<~RUBY
      expect(user.id).must_be_instance_of Integer
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts expect(...).to be_kind_of(Class) to expect(...).must_be_kind_of" do
    source = <<~RUBY
      expect(user).to be_kind_of(User)
    RUBY

    expected = <<~RUBY
      expect(user).must_be_kind_of User
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts expect(...).not_to be_a(Class) to expect(...).wont_be_instance_of" do
    source = <<~RUBY
      expect(user).not_to be_a(String)
    RUBY

    expected = <<~RUBY
      expect(user).wont_be_instance_of String
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts be_a_kind_of to must_be_kind_of" do
    source = <<~RUBY
      expect(user).to be_a_kind_of(User)
    RUBY

    expected = <<~RUBY
      expect(user).must_be_kind_of User
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "does not convert expect syntax inside strings" do
    source = <<~RUBY
      message = 'expect(user).to be_a(User)'
    RUBY

    expect(convert(source)).must_equal source
  end
end
