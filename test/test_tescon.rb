# frozen_string_literal: true

require_relative "test_helper"

describe Tescon do
  it "has a version number" do
    expect(Tescon::VERSION).must_be_kind_of String
  end
end
