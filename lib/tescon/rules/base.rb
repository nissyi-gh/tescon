# frozen_string_literal: true

module Tescon
  module Rules
    # Common entry point for rules that return findings.
    class Base
      def analyze(source_file)
        self.class::Visitor.findings(source_file)
      end
    end
  end
end
