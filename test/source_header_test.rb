# frozen_string_literal: true

require_relative "test_helper"

describe Tescon::SourceHeader do
  def apply(source, path = "spec/models/user_spec.rb")
    Tescon::SourceHeader.new.apply(source, path).source
  end

  it "inserts a converted-from comment at the top" do
    source = <<~RUBY
      RSpec.describe User do
      end
    RUBY

    expected = <<~RUBY
      # tescon: converted from spec/models/user_spec.rb
      RSpec.describe User do
      end
    RUBY

    expect(apply(source)).must_equal expected
  end

  it "inserts after frozen_string_literal" do
    source = <<~RUBY
      # frozen_string_literal: true

      RSpec.describe User do
      end
    RUBY

    expected = <<~RUBY
      # frozen_string_literal: true
      # tescon: converted from spec/models/user_spec.rb

      RSpec.describe User do
      end
    RUBY

    expect(apply(source)).must_equal expected
  end

  it "does not duplicate the comment on the second run" do
    source = <<~RUBY
      RSpec.describe User do
      end
    RUBY

    first = apply(source)
    second = apply(first)

    expect(second).must_equal first
    expect(second.scan("# tescon: converted from").length).must_equal 1
  end

  it "replaces the comment when the source path changes" do
    source = apply(<<~RUBY, "spec/models/user_spec.rb")
      RSpec.describe User do
      end
    RUBY

    result = Tescon::SourceHeader.new.apply(source, "spec/models/admin_spec.rb").source

    expect(result).must_include("# tescon: converted from spec/models/admin_spec.rb")
    expect(result).wont_include("user_spec.rb")
  end
end
