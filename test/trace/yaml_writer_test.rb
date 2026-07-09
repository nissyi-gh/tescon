# frozen_string_literal: true

require "test_helper"
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
      description: "marks as paid"
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
      attributes: { "status" => "paid" }
    )
    recorder.exit_factory_call
    recorder.finish_example

    path = File.join(Dir.tmpdir, "tescon-provenance-#{Process.pid}.yml")
    Tescon::Trace::YamlWriter.new(path).dump(recorder)

    data = YAML.safe_load(File.read(path))
    expect(data["examples"].length).must_equal 1
    expect(data["examples"].first["factory_calls"].first["factory"]).must_equal "order"
    expect(data["examples"].first["factory_calls"].first["traits"]).must_equal ["paid"]
    expect(data["examples"].first["factory_calls"].first["records"].first["classification"]).must_equal "setup"
  ensure
    File.delete(path) if path && File.exist?(path)
  end
end
