# frozen_string_literal: true

require_relative "analyzer"
require_relative "rewriter"

module Tescon
  class Converter
    def self.convert(source)
      new(source).convert
    end

    attr_accessor :converted

    def initialize(source, path: "(source)")
      @source = source
      @path = path
      @converted = source
    end

    def convert
      source_file = SourceFile.new(path: @path, source: @source)
      analysis_result = Analyzer.new.analyze(source_file)
      rewrite_result = Rewriter.new.rewrite(analysis_result)

      @converted = rewrite_result.converted_source
      @converted
    end
  end
end
