# frozen_string_literal: true

require_relative "tescon/analyzer"
require_relative "tescon/annotator"
require_relative "tescon/cli"
require_relative "tescon/converter"
require_relative "tescon/fixtures_hint"
require_relative "tescon/rewriter"
require_relative "tescon/source_header"
require_relative "tescon/version"

module Tescon
  class Error < StandardError; end
  # Your code goes here...
end
