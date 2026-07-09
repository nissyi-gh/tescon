# frozen_string_literal: true

module Tescon
  module Trace
    # Patches ActiveRecord persistence to record inserted rows.
    module ActiveRecord
      module RecordCreate
        def _create_record(*)
          result = super
          capture_record(self)
          result
        end

        private

        def capture_record(record)
          return unless record.persisted?

          Tescon::Trace.recorder.record_insert(
            model: record.class.name,
            table: record.class.table_name,
            id: record.id,
            attributes: record.attributes
          )
        rescue Tescon::Error
          nil
        end
      end

      def self.install!
        return if @installed
        return unless defined?(::ActiveRecord::Base)

        ::ActiveRecord::Base.prepend(RecordCreate)
        @installed = true
      end
    end
  end
end
