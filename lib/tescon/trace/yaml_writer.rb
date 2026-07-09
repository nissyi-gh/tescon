# frozen_string_literal: true

require "fileutils"
require "yaml"

require_relative "recorder"

module Tescon
  module Trace
    # Serializes a Recorder to provenance YAML.
    class YamlWriter
      DEFAULT_PATH = "tmp/tescon/provenance.yml"

      def self.dump(recorder, path: ENV.fetch("TESCON_TRACE_PATH", DEFAULT_PATH))
        new(path).dump(recorder)
      end

      def initialize(path)
        @path = path
      end

      def dump(recorder)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, YAML.dump(recorder.to_h))
        path
      end

      private

      attr_reader :path
    end
  end
end
