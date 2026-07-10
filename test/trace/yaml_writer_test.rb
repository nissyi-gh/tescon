# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "yaml"
require "tescon/trace/recorder"
require "tescon/trace/yaml_writer"

describe Tescon::Trace::YamlWriter do
  it "writes provenance YAML for a recorder" do
    recorder = Tescon::Trace::Recorder.new
    recorder.start_example(
      id: "spec/models/order_spec.rb:42",
      file: "spec/models/order_spec.rb",
      line: 42,
      description: "marks as paid",
      full_description: "Order#paid marks as paid"
    )
    recorder.enter_factory_call(
      strategy: :create,
      factory_name: :order,
      traits: [:paid],
      overrides: {},
      caller: "spec/models/order_spec.rb:45"
    )
    recorder.record_insert(
      model: "Order",
      table: "orders",
      id: 1,
      attributes: {
        "id" => 1,
        "status" => "paid",
        "created_at" => Time.utc(2026, 7, 10, 16, 11, 8),
        "updated_at" => Time.utc(2026, 7, 10, 16, 11, 8)
      }
    )
    recorder.exit_factory_call
    recorder.finish_example

    output_dir = File.join(Dir.tmpdir, "tescon-provenance-#{Process.pid}")
    paths = Tescon::Trace::YamlWriter.new(output_dir).dump_all(recorder)

    expect(paths.length).must_equal 1
    data = YAML.safe_load(File.read(paths.first))
    expect(data["meta"]["schema_version"]).must_equal "1"
    expect(data["meta"]["source_spec"]).must_equal "spec/models/order_spec.rb"
    expect(data["examples"].length).must_equal 1
    expect(data["examples"].first["full_description"]).must_equal "Order#paid marks as paid"
    expect(data["examples"].first["factory_calls"].first["call_id"]).must_equal 1
    expect(data["examples"].first["factory_calls"].first["factory"]).must_equal "order"
    expect(data["examples"].first["factory_calls"].first["traits"]).must_equal ["paid"]
    record = data["examples"].first["factory_calls"].first["records"].first
    expect(record["classification"]).must_equal "setup"
    expect(record["attributes"]).must_equal("status" => "paid")
  ensure
    FileUtils.rm_rf(output_dir) if output_dir && Dir.exist?(output_dir)
  end

  it "serializes rails_env as a string" do
    rails = Class.new do
      def self.env
        Struct.new(:to_s).new("test")
      end
    end
    output_dir = nil
    had_rails = Object.const_defined?(:Rails)
    original_rails = Object.const_get(:Rails) if had_rails
    Object.const_set(:Rails, rails)
    begin
      recorder = Tescon::Trace::Recorder.new
      recorder.start_example(
        id: "spec/models/user_spec.rb:10",
        file: "spec/models/user_spec.rb",
        line: 10,
        description: "creates user"
      )
      recorder.finish_example

      output_dir = File.join(Dir.tmpdir, "tescon-provenance-rails-env-#{Process.pid}")
      paths = Tescon::Trace::YamlWriter.new(output_dir).dump_all(recorder)

      data = YAML.safe_load(File.read(paths.first))
      expect(data["meta"]["rails_env"]).must_equal "test"
    ensure
      if had_rails
        Object.const_set(:Rails, original_rails)
      else
        Object.send(:remove_const, :Rails)
      end
      FileUtils.rm_rf(output_dir) if output_dir && Dir.exist?(output_dir)
    end
  end

  it "writes separate files per spec file" do
    recorder = Tescon::Trace::Recorder.new

    recorder.start_example(
      id: "spec/models/user_spec.rb:10",
      file: "spec/models/user_spec.rb",
      line: 10,
      description: "creates user"
    )
    recorder.finish_example

    recorder.start_example(
      id: "spec/models/order_spec.rb:20",
      file: "spec/models/order_spec.rb",
      line: 20,
      description: "creates order"
    )
    recorder.finish_example

    output_dir = File.join(Dir.tmpdir, "tescon-provenance-split-#{Process.pid}")
    paths = Tescon::Trace::YamlWriter.new(output_dir).dump_all(recorder)

    expect(paths.length).must_equal 2
    expect(paths).must_include File.join(output_dir, "spec/models/user_spec.yml")
    expect(paths).must_include File.join(output_dir, "spec/models/order_spec.yml")
  ensure
    FileUtils.rm_rf(output_dir) if output_dir && Dir.exist?(output_dir)
  end
end
