# frozen_string_literal: true

require_relative "expect_matcher"

module Tescon
  module Rules
    class ExpectMatch < ExpectMatcher
      matcher_config(
        rule_name: "expect_match",
        matchers: { match: { to: "must_match", not_to: "wont_match" } },
        message: "Convert RSpec %{matcher} expectation to minitest match assertion",
        requires_argument: true
      )
    end
  end
end
