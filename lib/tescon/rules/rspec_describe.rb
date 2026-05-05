# frozen_string_literal: true

module Tescon
  module Rules
    # Finds RSpec.describe calls that can be translated to minitest describe calls.
    class RspecDescribe
      RULE_NAME = "rspec_describe"

      def analyze(source_file)
        source_file.source.to_enum(:scan, /RSpec\.describe/).map do
          Finding.new(
            rule_name: RULE_NAME,
            message: "Convert RSpec.describe to minitest describe",
            start_offset: Regexp.last_match.begin(0),
            end_offset: Regexp.last_match.end(0),
            replacement: "describe"
          )
        end
      end
    end
  end
end
