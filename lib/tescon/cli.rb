# frozen_string_literal: true

require "optparse"

require_relative "analyzer"
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

        opts.on("-h", "--help", "Show this message") do
          @stdout.puts opts.help
          @early_exit = true
        end

        opts.on("-v", "--version", "Show tescon version") do
          @stdout.puts "tescon #{Tescon::VERSION}"
          @early_exit = true
        end
      end

      parser.parse(@argv)
    end

    def process(paths)
      changed_files = 0
      findings_by_rule = Hash.new(0)
      had_error = false

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

        @stdout.print(converted) unless @write
      end

      @stdout.flush if @stdout.respond_to?(:flush)
      print_summary(changed_files, findings_by_rule)
      had_error ? 1 : 0
    end

    def convert_file(path)
      source = File.read(path)
      source_file = SourceFile.new(path: path, source: source)
      rewrite_result = Rewriter.new.rewrite(Analyzer.new.analyze(source_file))
      [source, rewrite_result.converted_source, rewrite_result.changes]
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
