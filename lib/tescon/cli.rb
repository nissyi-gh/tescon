# frozen_string_literal: true

require "optparse"

require_relative "analyzer"
require_relative "fixtures_hint"
require_relative "rewriter"
require_relative "version"

module Tescon
  # Command-line entry point for tescon.
  class CLI
    BANNER = "Usage: tescon [options] FILE [FILE ...]"

    def initialize(argv, stdout: $stdout, stderr: $stderr)
      @argv = argv
      @stdout = stdout
      @stderr = stderr
      @write = false
      @output_path = nil
      @fixtures_hints = false
    end

    def run
      paths = parse_options
      return 0 if @early_exit

      if paths.empty?
        @stderr.puts BANNER
        return 1
      end

      process(paths)
    rescue OptionParser::ParseError => e
      @stderr.puts "tescon: #{e.message}"
      @stderr.puts BANNER
      1
    end

    private

    def parse_options
      parser = OptionParser.new do |opts|
        opts.banner = BANNER

        opts.on("-w", "--write", "Overwrite input files in place") { @write = true }
        opts.on("-o", "--output PATH", "Write output to PATH") { |path| @output_path = path }
        opts.on("--fixtures-hints", "Print FactoryBot fixture YAML hints") { @fixtures_hints = true }

        opts.on("-h", "--help", "Show this message") do
          @stdout.puts opts.help
          @early_exit = true
        end

        opts.on("-v", "--version", "Show tescon version") do
          @stdout.puts "tescon #{Tescon::VERSION}"
          @early_exit = true
        end
      end

      paths = parser.parse(@argv)
      raise OptionParser::InvalidOption, "cannot use --write with --output" if @write && @output_path

      paths
    end

    def process(paths)
      return process_fixture_hints(paths) if @fixtures_hints

      changed_files = 0
      findings_by_rule = Hash.new(0)
      had_error = false
      output = +""

      paths.each do |path|
        result = convert_file(path)
        unless result
          had_error = true
          next
        end

        source, converted, findings = result
        changed = converted != source

        if changed
          changed_files += 1
          findings.each { |finding| findings_by_rule[finding.rule_name] += 1 }
          File.write(path, converted) if @write
        end

        output << converted unless @write
      end

      write_output(output) unless @write
      print_summary(changed_files, findings_by_rule)
      had_error ? 1 : 0
    end

    def process_fixture_hints(paths)
      results = []
      had_error = false

      paths.each do |path|
        result = analyze_file(path)
        unless result
          had_error = true
          next
        end

        results << result
      end

      output = FixturesHint.format(results)
      write_output(output)
      @stderr.puts("No fixture hints.") if output.empty?
      had_error ? 1 : 0
    end

    def write_output(output)
      if @output_path
        File.write(@output_path, output)
      else
        @stdout.print(output)
        @stdout.flush if @stdout.respond_to?(:flush)
      end
    end

    def convert_file(path)
      analysis_result = analyze_file(path)
      return unless analysis_result

      rewrite_result = Rewriter.new.rewrite(analysis_result)
      [analysis_result.source_file.source, rewrite_result.converted_source, rewrite_result.changes]
    end

    def analyze_file(path)
      source = File.read(path)
      Analyzer.new.analyze(SourceFile.new(path: path, source: source))
    rescue Errno::ENOENT
      @stderr.puts "tescon: #{path}: file not found"
      nil
    rescue SystemCallError => e
      @stderr.puts "tescon: #{path}: #{e.message}"
      nil
    rescue StandardError => e
      @stderr.puts "tescon: #{path}: #{e.message}"
      nil
    end

    def print_summary(changed_files, findings_by_rule)
      if changed_files.zero?
        @stderr.puts "No changes."
        return
      end

      @stderr.puts "Changed #{changed_files} #{changed_files == 1 ? "file" : "files"}"
      width = findings_by_rule.keys.map(&:length).max
      findings_by_rule.sort.each do |rule_name, count|
        @stderr.puts "  #{rule_name.ljust(width)}  #{count}"
      end
    end
  end
end
