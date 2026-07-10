# frozen_string_literal: true

require "test_helper"
require "tescon/trace/config"

describe Tescon::Trace::Config do
  it "reads full attributes from environment" do
    with_env("TESCON_TRACE_FULL_ATTRIBUTES" => "1") do
      expect(Tescon::Trace::Config.new.full_attributes?).must_equal true
    end

    with_env("TESCON_TRACE_FULL_ATTRIBUTES" => nil) do
      expect(Tescon::Trace::Config.new.full_attributes?).must_equal false
    end
  end

  private

  def with_env(overrides)
    original = overrides.keys.to_h { |key| [key, ENV[key]] }
    overrides.each { |key, value| ENV[key] = value }
    yield
  ensure
    original.each do |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
  end
end
