# frozen_string_literal: true

require "stringio"
require "tempfile"

require_relative "test_helper"

describe Tescon::CLI do
  def run_cli(argv)
    stdout = StringIO.new
    stderr = StringIO.new
    exit_code = Tescon::CLI.new(argv, stdout: stdout, stderr: stderr).run
    [exit_code, stdout.string, stderr.string]
  end

  def with_spec_file(source)
    file = Tempfile.new(["sample", "_spec.rb"])
    file.write(source)
    file.close
    yield file.path
  ensure
    file&.unlink
  end

  it "prints usage and exits 1 when no paths are given" do
    exit_code, stdout, stderr = run_cli([])

    expect(exit_code).must_equal 1
    expect(stdout).must_equal ""
    expect(stderr).must_match(/Usage: tescon/)
  end

  it "prints converted source to stdout in dry-run mode" do
    source = <<~RUBY
      RSpec.describe User do
        specify "works" do
          expect(user.name).to eq("Alice")
        end
      end
    RUBY

    with_spec_file(source) do |path|
      exit_code, stdout, stderr = run_cli([path])

      expect(exit_code).must_equal 0
      expect(stdout).must_match(/describe User do/)
      expect(stdout).must_match(/it "works" do/)
      expect(stdout).must_match(/must_equal "Alice"/)
      expect(stderr).must_match(/Changed 1 file/)
      expect(stderr).must_match(/expect_eq\s+1/)
      expect(File.read(path)).must_equal source
    end
  end

  it "writes converted source back to file with --write" do
    source = <<~RUBY
      RSpec.describe User do
      end
    RUBY

    with_spec_file(source) do |path|
      exit_code, stdout, stderr = run_cli(["--write", path])

      expect(exit_code).must_equal 0
      expect(stdout).must_equal ""
      expect(stderr).must_match(/Changed 1 file/)
      expect(File.read(path)).must_match(/^describe User do/)
    end
  end

  it "reports no changes when source already matches target" do
    source = <<~RUBY
      describe User do
      end
    RUBY

    with_spec_file(source) do |path|
      exit_code, stdout, stderr = run_cli([path])

      expect(exit_code).must_equal 0
      expect(stdout).must_equal source
      expect(stderr).must_match(/No changes\./)
    end
  end

  it "prints FactoryBot fixture YAML hints" do
    source = <<~RUBY
      RSpec.describe User do
        context "with a name" do
          it "is valid" do
            create(:user, name: "Alice")
          end
        end
      end
    RUBY

    with_spec_file(source) do |path|
      exit_code, stdout, stderr = run_cli(["--fixtures-hints", path])
      basename = File.basename(path, ".rb")

      expect(exit_code).must_equal 0
      expect(stdout).must_match(/# #{basename}\.yml/)
      expect(stdout).must_match(/with_a_name_is_valid_user:/)
      expect(stdout).must_match(/name: "Alice"/)
      expect(stderr).must_equal ""
      expect(File.read(path)).must_equal source
    end
  end

  it "reports missing files and continues processing remaining paths" do
    source = <<~RUBY
      RSpec.describe User do
      end
    RUBY

    with_spec_file(source) do |path|
      exit_code, stdout, stderr = run_cli(["/no/such/file.rb", path])

      expect(exit_code).must_equal 1
      expect(stderr).must_match(%r{tescon: /no/such/file\.rb: file not found})
      expect(stdout).must_match(/^describe User do/)
    end
  end

  it "prints help to stdout and exits 0" do
    exit_code, stdout, stderr = run_cli(["--help"])

    expect(exit_code).must_equal 0
    expect(stdout).must_match(/Usage: tescon/)
    expect(stdout).must_match(/--write/)
    expect(stdout).must_match(/--fixtures-hints/)
    expect(stderr).must_equal ""
  end

  it "prints version to stdout and exits 0" do
    exit_code, stdout, stderr = run_cli(["--version"])

    expect(exit_code).must_equal 0
    expect(stdout).must_equal "tescon #{Tescon::VERSION}\n"
    expect(stderr).must_equal ""
  end

  it "rejects unknown options" do
    exit_code, _stdout, stderr = run_cli(["--bogus"])

    expect(exit_code).must_equal 1
    expect(stderr).must_match(/invalid option/)
  end
end
