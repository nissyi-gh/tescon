# frozen_string_literal: true

require_relative "expect_matcher"

module Tescon
  module Rules
    class ExpectBeNil < ExpectMatcher
      matcher_config(
        rule_name: "expect_be_nil",
        matchers: { be_nil: { to: "must_be_nil", not_to: "wont_be_nil" } },
        message: "Convert RSpec %{matcher} expectation to minitest nil assertion"
      )
    end
  end
end
