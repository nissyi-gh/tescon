# frozen_string_literal: true

module Tescon
  SourceHeaderResult = Data.define(:source, :applied)

  # Inserts a file-level comment recording the original spec path.
  class SourceHeader
    PREFIX = "# tescon:"
    LABEL = "converted from"

    def apply(source, path)
      comment_line = "#{PREFIX} #{LABEL} #{path}\n"
      lines = source.lines
      existing_index = existing_comment_index(lines)

      if existing_index
        return SourceHeaderResult.new(source: source, applied: false) if lines[existing_index] == comment_line

        lines[existing_index] = comment_line
        return SourceHeaderResult.new(source: lines.join, applied: true)
      end

      lines.insert(insert_index(lines), comment_line)
      SourceHeaderResult.new(source: lines.join, applied: true)
    end

    private

    def existing_comment_index(lines)
      lines.each_with_index do |line, index|
        return index if line.start_with?("#{PREFIX} #{LABEL} ")
      end

      nil
    end

    def insert_index(lines)
      index = 0
      return index if lines.empty?

      index += 1 if lines[index].match?(/\A# frozen_string_literal:\s*(?:true|false)/)

      index
    end
  end
end
