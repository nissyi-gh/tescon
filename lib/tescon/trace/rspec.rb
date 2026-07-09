# frozen_string_literal: true

module Tescon
  module Trace
    # Hooks RSpec examples and suite teardown to drive the recorder.
    module RSpec
      def self.install!
        return if @installed

        ::RSpec.configure do |config|
          config.around(:example) do |example|
            metadata = example.metadata
            Tescon::Trace.recorder.start_example(
              id: "#{metadata[:file_path]}:#{metadata[:line_number]}",
              file: metadata[:file_path],
              line: metadata[:line_number],
              description: example.description
            )

            example.run
          ensure
            Tescon::Trace.recorder.finish_example
          end

          config.after(:suite) do
            Tescon::Trace::YamlWriter.dump(Tescon::Trace.recorder)
          end
        end

        @installed = true
      end
    end
  end
end
