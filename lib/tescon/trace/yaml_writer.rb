# frozen_string_literal: true

require "fileutils"
require "yaml"

require_relative "../version"
require_relative "recorder"
require_relative "path_normalizer"

module Tescon
  module Trace
    # Serializes a Recorder to provenance YAML.
    class YamlWriter
      HEADER = <<~HEADER.chomp
        # Tescon provenance YAML
        # Observation log of FactoryBot/AR inserts during RSpec.
        # Not a recommended fixture set.
        #
        # classification:
        #   setup       = inserted during FactoryBot create/create_list
        #   side_effect = inserted outside factory calls in the example
        #
        # Not recorded: build, build_stubbed, attributes_for
      HEADER

      def self.dump_all(recorder, output_dir: Tescon::Trace.config.output_dir)
        new(output_dir).dump_all(recorder)
      end

      def initialize(output_dir)
        @output_dir = output_dir
      end

      def dump_all(recorder)
        recorder.examples_by_file.map do |source_spec, examples|
          dump_file(recorder, examples, source_spec: source_spec)
        end
      end

      def dump_file(recorder, examples, source_spec:)
        relative_path = PathNormalizer.relativize_spec_path(source_spec)
        path = File.join(output_dir, "#{relative_path}.yml")
        FileUtils.mkdir_p(File.dirname(path))

        data = {
          "meta" => build_meta(source_spec),
          "examples" => recorder.example_hashes(examples: examples)
        }

        yaml_body = YAML.dump(data).sub(/\A---\n/, "")
        File.write(path, "#{HEADER}\n---\n#{yaml_body}")
        path
      end

      private

      attr_reader :output_dir

      def build_meta(source_spec)
        meta = {
          "schema_version" => "1",
          "generated_by" => "tescon",
          "source_spec" => PathNormalizer.relativize(source_spec),
          "generated_at" => Time.now.utc.iso8601(3),
          "tescon_version" => Tescon::VERSION
        }
        meta["rails_env"] = ::Rails.env if defined?(::Rails) && ::Rails.respond_to?(:env)
        meta
      end
    end
  end
end
