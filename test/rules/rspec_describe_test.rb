# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::RspecDescribe do
  def convert(source)
    source_file = Tescon::SourceFile.new(path: "user_spec.rb", source: source)
    analysis_result = Tescon::AnalysisResult.new(
      source_file: source_file,
      findings: Tescon::Rules::RspecDescribe.new.analyze(source_file)
    )

    Tescon::Rewriter.new.rewrite(analysis_result).converted_source
  end

  it "converts RSpec.describe to minitest describe" do
    source = <<~RUBY
      RSpec.describe User do
      end
    RUBY

    expected = <<~RUBY
      describe User do
      end
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "leaves RSpec.describe with type: :model to model_describe" do
    source = <<~RUBY
      RSpec.describe User, type: :model do
      end
    RUBY

    expect(convert(source)).must_equal source
  end

  it "does not convert RSpec.describe inside strings" do
    source = <<~RUBY
      message = 'RSpec.describe User do end'
    RUBY

    expect(convert(source)).must_equal source
  end

  it "does not convert receiver method calls" do
    source = <<~RUBY
      helper.RSpec.describe User do
      end
    RUBY

    expect(convert(source)).must_equal source
  end
end
