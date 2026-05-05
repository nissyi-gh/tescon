# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::FactoryBot do
  def analyze(source)
    source_file = Tescon::SourceFile.new(path: "spec/models/user_spec.rb", source: source)

    Tescon::Rules::FactoryBot.new.analyze(source_file)
  end

  it "finds FactoryBot create calls with literal attributes and test context" do
    source = <<~RUBY
      RSpec.describe User do
        context "with a name" do
          it "is valid" do
            create(:user, name: "Alice", age: 20, admin: true)
          end
        end
      end
    RUBY

    usage = analyze(source).first

    expect(usage.strategy).must_equal :create
    expect(usage.factory_name).must_equal "user"
    expect(usage.context).must_equal ["User", "with a name", "is valid"]
    expect(usage.line).must_equal 4
    expect(usage.attributes.map(&:name)).must_equal %w[name age admin]
    expect(usage.attributes.map(&:value)).must_equal ["Alice", 20, true]
  end

  it "finds explicit FactoryBot receiver calls" do
    source = <<~RUBY
      specify "creates an admin" do
        FactoryBot.build_stubbed(:admin, role: :owner)
      end
    RUBY

    usage = analyze(source).first

    expect(usage.strategy).must_equal :build_stubbed
    expect(usage.factory_name).must_equal "admin"
    expect(usage.context).must_equal ["creates an admin"]
    expect(usage.attributes.first.literal).must_equal false
    expect(usage.attributes.first.source).must_equal ":owner"
  end

  it "ignores non FactoryBot receiver calls" do
    source = <<~RUBY
      helper.create(:user, name: "Alice")
    RUBY

    expect(analyze(source)).must_equal []
  end
end
