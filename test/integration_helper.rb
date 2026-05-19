# frozen_string_literal: true

# End-to-end conversion via Converter (all DEFAULT_RULES).
#
# Integration tests use whole spec files copied from typical Rails apps:
# mixed supported/unsupported matchers, unchanged let/build/create, and
# lines that stay as-is on purpose. Per-rule edge cases → test/rules/.
module TesconIntegration
  def assert_converts(source, expected, path: "(spec)")
    actual = Tescon::Converter.new(source, path: path).convert

    expect(actual).must_equal expected
  end
end

class Minitest::Spec
  include TesconIntegration
end
