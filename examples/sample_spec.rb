# frozen_string_literal: true

RSpec.describe User, type: :model do
  subject(:user) { User.new(name: "Alice") }

  context "when the user has a name" do
    specify "returns the name" do
      expect(user.name).to eq("Alice")
    end
  end

  context "when comparing nested values" do
    subject do
      User.new(name: default_names.fetch(:first))
    end

    specify "matches the default name" do
      expect(user.names.fetch(0)).to eq(default_names.fetch(:first))
    end
  end

  context "when the user is anonymous" do
    subject(:user) { User.new(name: nil) }

    specify "does not have Alice as a name" do
      expect(user.name).not_to eq("Alice")
    end
  end

  specify "does not convert text inside strings" do
    message = 'context "example" do subject(:user) { User.new } expect(user.name).to eq("Alice")'

    expect(message).to eq(message)
  end
end
