# frozen_string_literal: true

require "test_helper"
require "tescon/trace/path_normalizer"

describe Tescon::Trace::PathNormalizer do
  it "relativizes absolute paths from project root" do
    root = "/app"
    path = "/app/spec/models/user_spec.rb:42"

    expect(Tescon::Trace::PathNormalizer.relativize_caller(path, root: root)).must_equal(
      "spec/models/user_spec.rb:42"
    )
  end

  it "leaves already-relative paths unchanged" do
    expect(Tescon::Trace::PathNormalizer.relativize("spec/models/user_spec.rb")).must_equal(
      "spec/models/user_spec.rb"
    )
  end

  it "builds provenance file paths from spec paths" do
    expect(Tescon::Trace::PathNormalizer.relativize_spec_path("spec/models/user_spec.rb")).must_equal(
      "spec/models/user_spec"
    )
  end
end
