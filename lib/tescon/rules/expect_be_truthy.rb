# frozen_string_literal: true

require_relative "expect_matcher"

module Tescon
  module Rules
    class ExpectBeTruthy < ExpectMatcher
      matcher_config(
        rule_name: "expect_be_truthy",
        matchers: {
          be_truthy: { to: "must_equal true", not_to: "wont_equal true" },
          be_falsey: { to: "must_equal false", not_to: "wont_equal false" }
        },
        message: "Convert RSpec %{matcher} expectation to minitest assertion"
      )
    end
  end
end
