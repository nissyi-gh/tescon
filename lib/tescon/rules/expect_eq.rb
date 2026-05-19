# frozen_string_literal: true

require_relative "expect_matcher"

module Tescon
  module Rules
    class ExpectEq < ExpectMatcher
      matcher_config(
        rule_name: "expect_eq",
        matchers: { eq: { to: "must_equal", not_to: "wont_equal" } },
        message: "Convert RSpec %{matcher} expectation to minitest equality assertion",
        requires_argument: true
      )
    end
  end
end
