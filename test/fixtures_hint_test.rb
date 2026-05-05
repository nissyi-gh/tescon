# frozen_string_literal: true

require_relative "test_helper"

describe Tescon::FixturesHint do
  it "formats fixture hints with the source test filename and test-derived names" do
    source = <<~RUBY
      RSpec.describe User do
        context "with a name" do
          it "is valid" do
            create(:user, name: "Alice", token: token)
          end
        end
      end
    RUBY
    source_file = Tescon::SourceFile.new(path: "spec/models/user_spec.rb", source: source)
    result = Tescon::Analyzer.new.analyze(source_file)

    expected = <<~YAML
      # user_spec.yml
      with_a_name_is_valid_user:
        name: "Alice"
        # TODO: token: token
    YAML

    expect(Tescon::FixturesHint.format(result)).must_equal expected
  end

  it "falls back to the source file and line when no test context is available" do
    source = <<~RUBY
      user = build(:user)
    RUBY
    source_file = Tescon::SourceFile.new(path: "spec/models/user_spec.rb", source: source)
    result = Tescon::Analyzer.new.analyze(source_file)

    expected = <<~YAML
      # user_spec.yml
      user_spec_l1_user: {}
    YAML

    expect(Tescon::FixturesHint.format(result)).must_equal expected
  end

  it "makes duplicate fixture names unique within the same test file" do
    source = <<~RUBY
      context "with a name" do
        it "is valid" do
          create(:user, name: "Alice")
          create(:user, name: "Bob")
        end
      end
    RUBY
    source_file = Tescon::SourceFile.new(path: "spec/models/user_spec.rb", source: source)
    result = Tescon::Analyzer.new.analyze(source_file)

    expected = <<~YAML
      # user_spec.yml
      with_a_name_is_valid_user:
        name: "Alice"
      with_a_name_is_valid_user_2:
        name: "Bob"
    YAML

    expect(Tescon::FixturesHint.format(result)).must_equal expected
  end
end
