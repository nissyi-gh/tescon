# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Notices::BeforeAll do
  def notices_for(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    Tescon::Notices::BeforeAll.new.analyze(source_file)
  end

  it "flags before(:all) for review" do
    source = <<~RUBY
      describe User do
        before(:all) do
          @user = User.new
        end
      end
    RUBY

    result = notices_for(source)

    expect(result.length).must_equal 1
    expect(result.first.rule_name).must_equal "before_all"
    expect(result.first.line).must_equal 2
    expect(result.first.severity).must_equal :review
  end

  it "flags after(:all) for review" do
    source = <<~RUBY
      after(:all) do
      end
    RUBY

    result = notices_for(source)

    expect(result.length).must_equal 1
    expect(result.first.rule_name).must_equal "before_all"
    expect(result.first.line).must_equal 1
  end

  it "does not flag before(:each)" do
    source = <<~RUBY
      before(:each) do
      end
    RUBY

    expect(notices_for(source)).must_be_empty
  end

  it "does not flag bare before blocks" do
    source = <<~RUBY
      before do
      end
    RUBY

    expect(notices_for(source)).must_be_empty
  end
end
