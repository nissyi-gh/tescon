# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::ModelDescribe do
  def convert(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    analysis_result = Tescon::AnalysisResult.new(
      source_file: source_file,
      findings: Tescon::Rules::ModelDescribe.new.analyze(source_file)
    )

    Tescon::Rewriter.new.rewrite(analysis_result).converted_source
  end

  def convert_all(source)
    Tescon::Converter.new(source, path: "spec/models/user_spec.rb").convert
  end

  it "converts describe Constant, type: :model to ActiveSupport::TestCase" do
    source = <<~RUBY
      describe Todo, type: :model do
        it "works" do
        end
      end
    RUBY

    expected = <<~RUBY
      class TodoTest < ActiveSupport::TestCase
        extend Minitest::Spec::DSL

        it "works" do
        end
      end
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts RSpec.describe with type: :model in one pass via Converter" do
    source = <<~RUBY
      RSpec.describe User, type: :model do
        it "works" do
        end
      end
    RUBY

    expected = <<~RUBY
      class UserTest < ActiveSupport::TestCase
        extend Minitest::Spec::DSL

        it "works" do
        end
      end
    RUBY

    expect(convert_all(source)).must_equal expected
  end

  it "supports namespaced constants" do
    source = <<~RUBY
      describe Orders::Cancel, type: :model do
      end
    RUBY

    expected = <<~RUBY
      class Orders::CancelTest < ActiveSupport::TestCase
        extend Minitest::Spec::DSL

      end
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "does not convert string subjects" do
    source = <<~RUBY
      describe "Todo", type: :model do
      end
    RUBY

    expect(convert(source)).must_equal source
  end

  it "does not convert other type metadata" do
    source = <<~RUBY
      describe User, type: :request do
      end
    RUBY

    expect(convert(source)).must_equal source
  end

  it "does not convert describe without type metadata" do
    source = <<~RUBY
      describe User do
      end
    RUBY

    expect(convert(source)).must_equal source
  end
end
