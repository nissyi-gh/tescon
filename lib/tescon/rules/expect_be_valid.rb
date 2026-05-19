# frozen_string_literal: true

require_relative "expect_matcher"

module Tescon
  module Rules
    class ExpectBeValid < ExpectMatcher
      matcher_config(
        rule_name: "expect_be_valid",
        matchers: {
          be_valid: { to: "must_be :valid?", not_to: "wont_be :valid?" },
          be_invalid: { to: "must_be :invalid?", not_to: "wont_be :invalid?" }
        },
        message: "Convert RSpec %{matcher} expectation to minitest predicate assertion"
      )
    end
  end
end
