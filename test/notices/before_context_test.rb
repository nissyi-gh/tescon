# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Notices::BeforeContext do
  def notices_for(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    Tescon::Notices::BeforeContext.new.analyze(source_file)
  end

  it "flags before(:context) as todo" do
    source = <<~RUBY
      before(:context) do
        @user = User.new
      end
    RUBY

    result = notices_for(source)

    expect(result.length).must_equal 1
    expect(result.first.rule_name).must_equal "before_context"
    expect(result.first.severity).must_equal :todo
    expect(result.first.message).must_include("before(:all)")
  end

  it "does not flag before(:all)" do
    source = <<~RUBY
      before(:all) do
      end
    RUBY

    expect(notices_for(source)).must_be_empty
  end
end
