# frozen_string_literal: true

require "test_helper"
require "fileutils"
require_relative "../support/trace_stubs"
require "tescon/trace/attribute_normalizer"

describe Tescon::Trace::AttributeNormalizer do
  it "excludes id and timestamps by default" do
    attributes = {
      "id" => 1,
      "email" => "alice@example.com",
      "created_at" => Time.utc(2026, 7, 10, 16, 11, 8),
      "updated_at" => Time.utc(2026, 7, 10, 16, 11, 8)
    }

    normalized = Tescon::Trace::AttributeNormalizer.normalize(attributes)

    expect(normalized).must_equal(
      "email" => "alice@example.com"
    )
  end

  it "keeps id and timestamps when full attributes are enabled" do
    timestamp = Time.utc(2026, 7, 10, 16, 11, 8)
    attributes = {
      "id" => 1,
      "email" => "alice@example.com",
      "created_at" => timestamp,
      "updated_at" => timestamp
    }

    normalized = Tescon::Trace::AttributeNormalizer.normalize(attributes, full: true)

    expect(normalized["id"]).must_equal 1
    expect(normalized["email"]).must_equal "alice@example.com"
    expect(normalized["created_at"]).must_equal "2026-07-10T16:11:08.000Z"
    expect(normalized["updated_at"]).must_equal "2026-07-10T16:11:08.000Z"
  end

  it "serializes TimeWithZone-like values to ISO8601" do
    time_with_zone = Struct.new(:utc).new(Time.utc(2026, 7, 10, 16, 11, 8))

    normalized = Tescon::Trace::AttributeNormalizer.normalize(
      { "created_at" => time_with_zone },
      full: true
    )

    expect(normalized["created_at"]).must_equal "2026-07-10T16:11:08.000Z"
  end

  it "serializes BigDecimal values as strings" do
    begin
      require "bigdecimal"
    rescue LoadError
      skip "bigdecimal is not available"
    end

    normalized = Tescon::Trace::AttributeNormalizer.normalize(
      { "amount" => BigDecimal("12.5") },
      full: true
    )

    expect(normalized["amount"]).must_equal "12.5"
  end

  it "collapses ActiveRecord overrides to foreign key ids" do
    user = User.new("email" => "alice@example.com").tap(&:save)

    normalized = Tescon::Trace::AttributeNormalizer.normalize_overrides(
      "user" => user,
      "user_id" => user
    )

    expect(normalized).must_equal(
      "user_id" => user.id
    )
  end

  it "normalizes non-scalar override values" do
    timestamp = Time.utc(2026, 7, 10, 16, 11, 8)

    normalized = Tescon::Trace::AttributeNormalizer.normalize_overrides(
      "scheduled_at" => timestamp,
      "metadata" => { "source" => "spec" }
    )

    expect(normalized).must_equal(
      "scheduled_at" => "2026-07-10T16:11:08.000Z",
      "metadata" => { "source" => "spec" }
    )
  end
end
