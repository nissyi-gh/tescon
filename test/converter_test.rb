# frozen_string_literal: true

require_relative "test_helper"

describe Tescon::Converter do
  it "runs default rules and returns converted source" do
    source = <<~RUBY
      RSpec.describe User, type: :model do
        context "with a name" do
          subject(:user) { User.new(name: "Alice") }

          specify "has a name" do
            expect(user.name).to eq("Alice")
          end

          it { is_expected.to eq(User.new(name: "Alice")) }
        end
      end
    RUBY

    expected = <<~RUBY
      describe User, type: :model do
        describe "with a name" do
          let(:user) { User.new(name: "Alice") }

          it "has a name" do
            expect(user.name).must_equal "Alice"
          end

          it { user.must_equal User.new(name: "Alice") }
        end
      end
    RUBY

    expect(Tescon::Converter.convert(source)).must_equal expected
  end
end
