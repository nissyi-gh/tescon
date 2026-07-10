# frozen_string_literal: true

module Tescon
  module Trace
    # Patches ActiveRecord persistence to record inserted and updated rows.
    module ActiveRecord
      module RecordPersistence
        def _create_record(*)
          result = super
          capture_insert(self)
          result
        end

        def _update_record(*)
          result = super
          capture_update(self)
          result
        end

        private

        def capture_insert(record)
          return unless record.persisted?

          Tescon::Trace.recorder.record_insert(
            model: record.class.name,
            table: record.class.table_name,
            id: record.id,
            attributes: record.attributes
          )
        end

        def capture_update(record)
          return unless record.persisted?

          Tescon::Trace.recorder.record_update(
            model: record.class.name,
            table: record.class.table_name,
            id: record.id,
            attributes: record.attributes
          )
        end
      end

      def self.install!
        return if @installed
        return unless defined?(::ActiveRecord::Base)

        ::ActiveRecord::Base.prepend(RecordPersistence)
        @installed = true
      end
    end
  end
end
