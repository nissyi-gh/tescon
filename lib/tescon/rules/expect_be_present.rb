# frozen_string_literal: true

require_relative "expect_matcher"

module Tescon
  module Rules
    class ExpectBePresent < ExpectMatcher
      matcher_config(
        rule_name: "expect_be_present",
        matchers: {
          be_present: { to: "must_be :present?", not_to: "wont_be :present?" },
          be_blank: { to: "must_be :blank?", not_to: "wont_be :blank?" },
          be_empty: { to: "must_be :empty?", not_to: "wont_be :empty?" }
        },
        message: "Convert RSpec %{matcher} expectation to minitest predicate assertion"
      )
    end
  end
end
