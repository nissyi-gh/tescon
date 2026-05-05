# frozen_string_literal: true

module Tescon
  RewriteResult = Data.define(:source_file, :converted_source, :changes)

  # Applies analysis findings to source text.
  class Rewriter
    def rewrite(analysis_result)
      findings = analysis_result.findings.sort_by(&:start_offset)
      converted_source = findings.reverse_each.each_with_object(analysis_result.source_file.source.dup) do |finding, source|
        # Prism uses byte offsets; String#[range]= indexes by character in UTF-8 strings.
        source.bytesplice(finding.start_offset, finding.end_offset - finding.start_offset, finding.replacement)
      end

      RewriteResult.new(
        source_file: analysis_result.source_file,
        converted_source: converted_source,
        changes: findings
      )
    end
  end
end
