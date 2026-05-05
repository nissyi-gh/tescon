# frozen_string_literal: true

require_relative "../test_helper"

describe Tescon::Rules::IsExpectedEq do
  def convert(source)
    Tescon::Converter.convert(source)
  end

  it "converts is_expected.to eq to subject.must_equal for unnamed subject" do
    source = <<~RUBY
      describe User do
        subject { User.new(name: "Alice") }

        it { is_expected.to eq(User.new(name: "Alice")) }
      end
    RUBY

    expected = <<~RUBY
      describe User do
        let(:subject) { User.new(name: "Alice") }

        it { subject.must_equal User.new(name: "Alice") }
      end
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts is_expected.to eq for named subject to let name" do
    source = <<~RUBY
      RSpec.describe User do
        subject(:user) { User.new(name: "Alice") }

        it { is_expected.to eq(User.new(name: "Alice")) }
      end
    RUBY

    expected = <<~RUBY
      describe User do
        let(:user) { User.new(name: "Alice") }

        it { user.must_equal User.new(name: "Alice") }
      end
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts is_expected.not_to eq to wont_equal" do
    source = <<~RUBY
      describe User do
        subject(:user) { User.new(name: nil) }

        it { is_expected.not_to eq(User.new(name: "Alice")) }
      end
    RUBY

    expected = <<~RUBY
      describe User do
        let(:user) { User.new(name: nil) }

        it { user.wont_equal User.new(name: "Alice") }
      end
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "inherits subject alias from outer group in nested describe" do
    source = <<~RUBY
      describe User do
        subject(:user) { User.new }

        describe "inner" do
          it { is_expected.to eq(user) }
        end
      end
    RUBY

    expected = <<~RUBY
      describe User do
        let(:user) { User.new }

        describe "inner" do
          it { user.must_equal user }
        end
      end
    RUBY

    expect(convert(source)).must_equal expected
  end

  it "converts expect(...).to eq via ExpectEq when using full Converter" do
    source = <<~RUBY
      it "example" do
        expect(user.name).to eq("Alice")
      end
    RUBY

    expected = <<~RUBY
      it "example" do
        expect(user.name).must_equal "Alice"
      end
    RUBY

    expect(convert(source)).must_equal expected
  end
end
