# frozen_string_literal: true

require_relative "expect_matcher"

module Tescon
  module Rules
    class ExpectInclude < ExpectMatcher
      matcher_config(
        rule_name: "expect_include",
        matchers: { include: { to: "must_include", not_to: "wont_include" } },
        message: "Convert RSpec %{matcher} expectation to minitest include assertion",
        requires_argument: true
      )
    end
  end
end
