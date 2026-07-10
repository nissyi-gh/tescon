# frozen_string_literal: true

require_relative "path_normalizer"

module Tescon
  module Trace
    # Hooks RSpec examples and suite teardown to drive the recorder.
    module RSpec
      def self.install!
        return if @installed

        ::RSpec.configure do |config|
          config.before(:context) do
            metadata = self.class.metadata
            Tescon::Trace.recorder.begin_context_setup(
              id: Tescon::Trace::RSpec.context_setup_id(metadata),
              file: PathNormalizer.relativize(metadata[:file_path]),
              line: metadata[:line_number],
              full_description: "#{metadata[:full_description]} [before_all setup]"
            )
          end

          config.after(:context) do
            metadata = self.class.metadata
            Tescon::Trace.recorder.end_context_setup(
              context_id: Tescon::Trace::RSpec.context_setup_id(metadata)
            )
          end

          config.around(:example) do |example|
            metadata = example.metadata
            Tescon::Trace.recorder.start_example(
              id: "#{metadata[:file_path]}:#{metadata[:line_number]}",
              file: PathNormalizer.relativize(metadata[:file_path]),
              line: metadata[:line_number],
              description: example.description,
              full_description: metadata[:full_description]
            )

            example.run
          ensure
            Tescon::Trace.recorder.finish_example
          end

          config.after(:suite) do
            Tescon::Trace::YamlWriter.dump_all(Tescon::Trace.recorder)
          end
        end

        @installed = true
      end

      def self.context_setup_id(metadata)
        "#{metadata[:file_path]}:before_context:#{metadata[:line_number]}"
      end
    end
  end
end
