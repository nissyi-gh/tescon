# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../integration_helper"

describe "typical model spec" do
  # 実アプリでよくある構成: shoulda / FactoryBot / 未対応マッチャが混在し、
  # 変換できる行だけが書き換わる。
  it "converts structure and supported expectations while leaving the rest intact" do
    source = <<~RUBY
      require "rails_helper"

      RSpec.describe User, type: :model do
        describe "associations" do
          it { is_expected.to belong_to(:organization) }
        end

        describe "validations" do
          subject { build(:user, email: email) }
          let(:email) { "alice@example.com" }

          context "when email is blank" do
            let(:email) { "" }

            it "is invalid" do
              expect(subject).not_to be_valid
              expect(subject.errors[:email]).to include("can't be blank")
            end
          end
        end

        describe "#display_name" do
          let(:user) { build(:user, first_name: "Alice", last_name: "Smith") }

          it "joins the name" do
            expect(user.display_name).to eq("Alice Smith")
          end
        end
      end
    RUBY

    expected = <<~RUBY
      require "rails_helper"

      class UserTest < ActiveSupport::TestCase
        extend Minitest::Spec::DSL

        describe "associations" do
          it { is_expected.to belong_to(:organization) }
        end

        describe "validations" do
          let(:subject) { build(:user, email: email) }
          let(:email) { "alice@example.com" }

          describe "when email is blank" do
            let(:email) { "" }

            it "is invalid" do
              expect(subject).wont_be :valid?
              expect(subject.errors[:email]).must_include "can't be blank"
            end
          end
        end

        describe "#display_name" do
          let(:user) { build(:user, first_name: "Alice", last_name: "Smith") }

          it "joins the name" do
            expect(user.display_name).must_equal "Alice Smith"
          end
        end
      end
    RUBY

    assert_converts source, expected, path: "spec/models/user_spec.rb"
  end
end
