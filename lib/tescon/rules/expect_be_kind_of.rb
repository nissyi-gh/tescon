# frozen_string_literal: true

require_relative "expect_matcher"

module Tescon
  module Rules
    class ExpectBeKindOf < ExpectMatcher
      matcher_config(
        rule_name: "expect_be_kind_of",
        matchers: {
          be_a: { to: "must_be_instance_of", not_to: "wont_be_instance_of" },
          be_an: { to: "must_be_instance_of", not_to: "wont_be_instance_of" },
          be_kind_of: { to: "must_be_kind_of", not_to: "wont_be_kind_of" },
          be_a_kind_of: { to: "must_be_kind_of", not_to: "wont_be_kind_of" }
        },
        message: "Convert RSpec %{matcher} expectation to minitest type assertion",
        requires_argument: true
      )
    end
  end
end
