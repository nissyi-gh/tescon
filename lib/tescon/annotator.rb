# frozen_string_literal: true

module Tescon
  AnnotateResult = Data.define(:source, :applied, :skipped)

  # Inserts review/todo comments above lines flagged by notice detectors.
  class Annotator
    PREFIX = "# tescon:"

    def apply(source, notices)
      applied = []
      skipped = []
      lines = source.lines

      notices.sort_by(&:line).reverse_each do |notice|
        index = notice.line - 1
        next if index.negative? || index >= lines.length

        if annotated?(lines, index, notice)
          skipped << notice
          next
        end

        lines.insert(index, comment_line(lines[index], notice))
        applied << notice
      end

      AnnotateResult.new(source: lines.join, applied: applied, skipped: skipped)
    end

    private

    def annotated?(lines, index, notice)
      return false if index.zero?

      previous = lines[index - 1]
      return false unless previous.lstrip.start_with?(PREFIX)

      previous.include?(tag(notice.rule_name))
    end

    def comment_line(target_line, notice)
      indent = target_line[/\A(\s*)/, 1]
      "#{indent}#{PREFIX} #{severity_label(notice.severity)} — #{tag(notice.rule_name)} #{notice.message}\n"
    end

    def severity_label(severity)
      severity.to_s
    end

    def tag(rule_name)
      "[#{rule_name}]"
    end
  end
end
