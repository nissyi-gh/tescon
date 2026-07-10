# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "yaml"
require_relative "../support/trace_stubs"
require "tescon/trace"

describe "Tescon runtime trace integration" do
  before do
    Tescon::Trace.reset!
    ActiveRecord::Base.sequence = 0
  end

  it "records factory calls and inserted records into provenance YAML" do
    Tescon::Trace.recorder.start_example(
      id: "spec/models/order_spec.rb:42",
      file: "spec/models/order_spec.rb",
      line: 42,
      description: "creates paid order",
      full_description: "Order creates paid order"
    )

    FactoryBot.create(:order, :paid, user_id: 1)
    FactoryBot.create(:user, email: "user@example.com")

    Order.new(status: "created_by_subject").save

    Tescon::Trace.recorder.finish_example

    output_dir = File.join(Dir.tmpdir, "tescon-integration-#{Process.pid}")
    paths = Tescon::Trace::YamlWriter.new(output_dir).dump_all(Tescon::Trace.recorder)
    data = YAML.safe_load(File.read(paths.first))

    example = data["examples"].first
    expect(data["meta"]["schema_version"]).must_equal "1"
    expect(example["factory_calls"].length).must_equal 2
    expect(example["factory_calls"].first["factory"]).must_equal "order"
    expect(example["factory_calls"].first["traits"]).must_equal ["paid"]
    expect(example["factory_calls"].first["records"].first["classification"]).must_equal "setup"
    expect(example["side_effect_records"].first["classification"]).must_equal "side_effect"
    expect(example["side_effect_records"].first["caller"]).wont_be_nil
  ensure
    FileUtils.rm_rf(output_dir) if output_dir && Dir.exist?(output_dir)
  end

  it "records create_list with parent_call_id" do
    Tescon::Trace.recorder.start_example(
      id: "spec/models/user_spec.rb:10",
      file: "spec/models/user_spec.rb",
      line: 10,
      description: "creates users"
    )

    FactoryBot.create_list(:user, 2, email: "user@example.com")

    Tescon::Trace.recorder.finish_example

    list_call = Tescon::Trace.recorder.examples.first.factory_calls.first
    child_calls = Tescon::Trace.recorder.examples.first.factory_calls[1..]

    expect(list_call.strategy).must_equal :create_list
    expect(list_call.count).must_equal 2
    expect(child_calls.length).must_equal 2
    expect(child_calls.map(&:parent_call_id).uniq).must_equal [list_call.call_id]

    output_dir = File.join(Dir.tmpdir, "tescon-integration-create-list-#{Process.pid}")
    paths = Tescon::Trace::YamlWriter.new(output_dir).dump_all(Tescon::Trace.recorder)
    data = YAML.safe_load(File.read(paths.first))
    child_calls_yaml = data["examples"].first["factory_calls"][1..]

    expect(child_calls_yaml.map { |call| call.key?("caller") }).must_equal [false, false]
  ensure
    FileUtils.rm_rf(output_dir) if output_dir && Dir.exist?(output_dir)
  end

  it "does not reinstall factory bot patches" do
    Tescon::Trace::FactoryBot.install!
    Tescon::Trace::FactoryBot.install!
  end
end
