# frozen_string_literal: true

require "test_helper"
require_relative "../support/trace_stubs"
require "tescon/trace/recorder"
require "tescon/trace/factory_bot"

describe Tescon::Trace::Recorder do
  it "records factory call inserts as setup and other inserts as side_effect" do
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
      model: "User",
      table: "users",
      id: 1,
      attributes: { "email" => "user@example.com" }
    )
    recorder.record_insert(
      model: "Order",
      table: "orders",
      id: 2,
      attributes: { "status" => "paid", "user_id" => 1 }
    )
    recorder.exit_factory_call

    recorder.record_insert(
      model: "Payment",
      table: "payments",
      id: 3,
      attributes: { "amount" => 100 }
    )

    recorder.finish_example

    example = recorder.examples.first
    expect(example.factory_calls.length).must_equal 1
    expect(example.factory_calls.first.records.map(&:classification)).must_equal %w[setup setup]
    expect(example.side_effect_records.first.classification).must_equal "side_effect"
    expect(example.side_effect_records.first.caller).wont_be_nil
  end

  it "associates nested factory call inserts with the inner call" do
    recorder = Tescon::Trace::Recorder.new

    recorder.start_example(
      id: "spec/models/order_spec.rb:10",
      file: "spec/models/order_spec.rb",
      line: 10,
      description: "creates order with user"
    )

    recorder.enter_factory_call(
      strategy: :create,
      factory_name: :order,
      traits: [],
      overrides: {},
      caller: "spec/models/order_spec.rb:12"
    )
    recorder.enter_factory_call(
      strategy: :create,
      factory_name: :user,
      traits: [],
      overrides: {},
      caller: "spec/models/order_spec.rb:13"
    )
    recorder.record_insert(
      model: "User",
      table: "users",
      id: 1,
      attributes: { "email" => "user@example.com" }
    )
    recorder.exit_factory_call
    recorder.record_insert(
      model: "Order",
      table: "orders",
      id: 2,
      attributes: { "user_id" => 1 }
    )
    recorder.exit_factory_call
    recorder.finish_example

    order_call = recorder.examples.first.factory_calls.first
    user_call = recorder.examples.first.factory_calls[1]

    expect(order_call.call_id).must_equal 1
    expect(user_call.call_id).must_equal 2
    expect(user_call.parent_call_id).must_equal 1
    expect(order_call.records.map(&:model)).must_equal %w[Order]
    expect(order_call.records.first.classification).must_equal "setup"
    expect(user_call.records.map(&:model)).must_equal %w[User]
    expect(user_call.records.first.via).must_equal "association"
    expect(order_call.records.first.links.first).must_equal(
      "attribute" => "user_id",
      "target_model" => "User",
      "target_id" => 1
    )
  end

  it "records create_list parent and child call ids" do
    recorder = Tescon::Trace::Recorder.new

    recorder.start_example(
      id: "spec/models/user_spec.rb:10",
      file: "spec/models/user_spec.rb",
      line: 10,
      description: "creates users"
    )

    recorder.enter_factory_call(
      strategy: :create_list,
      factory_name: :user,
      traits: [],
      overrides: {},
      count: 2,
      caller: "spec/models/user_spec.rb:12"
    )
    recorder.enter_factory_call(
      strategy: :create,
      factory_name: :user,
      traits: [],
      overrides: {},
      caller: "spec/models/user_spec.rb:13"
    )
    recorder.record_insert(
      model: "User",
      table: "users",
      id: 1,
      attributes: { "email" => "one@example.com" }
    )
    recorder.exit_factory_call
    recorder.enter_factory_call(
      strategy: :create,
      factory_name: :user,
      traits: [],
      overrides: {},
      caller: "spec/models/user_spec.rb:14"
    )
    recorder.record_insert(
      model: "User",
      table: "users",
      id: 2,
      attributes: { "email" => "two@example.com" }
    )
    recorder.exit_factory_call
    recorder.exit_factory_call
    recorder.finish_example

    list_call = recorder.examples.first.factory_calls.first
    child_calls = recorder.examples.first.factory_calls[1..]

    expect(list_call.strategy).must_equal :create_list
    expect(list_call.count).must_equal 2
    expect(child_calls.map(&:parent_call_id)).must_equal [1, 1]
  end

  it "normalizes ActiveRecord overrides into foreign keys" do
    recorder = Tescon::Trace::Recorder.new
    user = User.new("email" => "alice@example.com", "id" => 1).tap do |record|
      record.instance_variable_set(:@persisted, true)
    end

    recorder.start_example(
      id: "spec/models/order_spec.rb:10",
      file: "spec/models/order_spec.rb",
      line: 10,
      description: "creates order with user"
    )
    recorder.enter_factory_call(
      strategy: :create,
      factory_name: :order,
      traits: [],
      overrides: { user: user },
      caller: "spec/models/order_spec.rb:12"
    )
    recorder.exit_factory_call
    recorder.finish_example

    expect(recorder.examples.first.factory_calls.first.overrides).must_equal(
      "user_id" => user.id
    )
  end

  it "omits caller from nested factory calls with parent_call_id" do
    recorder = Tescon::Trace::Recorder.new

    recorder.start_example(
      id: "spec/models/user_spec.rb:10",
      file: "spec/models/user_spec.rb",
      line: 10,
      description: "creates users"
    )
    recorder.enter_factory_call(
      strategy: :create_list,
      factory_name: :user,
      traits: [],
      overrides: {},
      count: 2,
      caller: "spec/models/user_spec.rb:12"
    )
    recorder.enter_factory_call(
      strategy: :create,
      factory_name: :user,
      traits: [],
      overrides: {},
      caller: "spec/models/user_spec.rb:13"
    )
    recorder.exit_factory_call
    recorder.exit_factory_call
    recorder.finish_example

    example_hash = recorder.example_hashes.first
    parent_call = example_hash["factory_calls"].first
    child_call = example_hash["factory_calls"][1]

    expect(parent_call["caller"]).must_equal "spec/models/user_spec.rb:12"
    expect(child_call.key?("caller")).must_equal false
  end

  it "raises when recording outside an example" do
    recorder = Tescon::Trace::Recorder.new

    expect do
      recorder.enter_factory_call(
        strategy: :create,
        factory_name: :user,
        caller: "spec/models/user_spec.rb:1"
      )
    end.must_raise Tescon::Error
  end

  it "no-ops record_insert when no active example" do
    recorder = Tescon::Trace::Recorder.new

    expect(recorder.record_insert(model: "User", table: "users", id: 1, attributes: {})).must_be_nil
    expect(recorder.examples).must_be_empty
  end

  it "no-ops record_update when no active example" do
    recorder = Tescon::Trace::Recorder.new

    expect(recorder.record_update(model: "User", table: "users", id: 1, attributes: {})).must_be_nil
    expect(recorder.examples).must_be_empty
  end

  it "records factory calls during before(:context) setup" do
    recorder = Tescon::Trace::Recorder.new

    recorder.begin_context_setup(
      id: "spec/models/user_spec.rb:before_context:4",
      file: "spec/models/user_spec.rb",
      line: 4,
      full_description: "User [before_all setup]"
    )
    recorder.enter_factory_call(
      strategy: :create,
      factory_name: :user,
      traits: [],
      overrides: {},
      caller: "spec/models/user_spec.rb:5"
    )
    recorder.record_insert(
      model: "User",
      table: "users",
      id: 1,
      attributes: { "email" => "user@example.com" }
    )
    recorder.exit_factory_call
    recorder.end_context_setup(context_id: "spec/models/user_spec.rb:before_context:4")

    setup = recorder.examples.first
    expect(setup.role).must_equal "before_context"
    expect(setup.description).must_equal "[before_all setup]"
    expect(setup.factory_calls.length).must_equal 1
  end

  it "builds inherited_setup from nested before(:context) setups" do
    recorder = Tescon::Trace::Recorder.new

    recorder.begin_context_setup(
      id: "spec/models/order_spec.rb:before_context:4",
      file: "spec/models/order_spec.rb",
      line: 4,
      full_description: "Order [before_all setup]"
    )
    recorder.enter_factory_call(
      strategy: :create,
      factory_name: :user,
      traits: [],
      overrides: {},
      caller: "spec/models/order_spec.rb:5"
    )
    recorder.exit_factory_call

    recorder.begin_context_setup(
      id: "spec/models/order_spec.rb:before_context:20",
      file: "spec/models/order_spec.rb",
      line: 20,
      full_description: "Order when paid [before_all setup]"
    )
    recorder.enter_factory_call(
      strategy: :create,
      factory_name: :order,
      traits: [:paid],
      overrides: {},
      caller: "spec/models/order_spec.rb:21"
    )
    recorder.exit_factory_call

    recorder.start_example(
      id: "spec/models/order_spec.rb:30",
      file: "spec/models/order_spec.rb",
      line: 30,
      description: "returns paid order"
    )
    recorder.finish_example

    example = recorder.examples.last
    expect(example.inherited_setup).must_equal(
      [
        { "from" => "spec/models/order_spec.rb:before_context:4" },
        { "from" => "spec/models/order_spec.rb:before_context:20" }
      ]
    )
  end

  it "records updates as side_effect records" do
    recorder = Tescon::Trace::Recorder.new

    recorder.start_example(
      id: "spec/models/user_spec.rb:10",
      file: "spec/models/user_spec.rb",
      line: 10,
      description: "updates nickname"
    )
    recorder.record_update(
      model: "User",
      table: "users",
      id: 1,
      attributes: { "email" => "user@example.com", "nickname" => "たろちゃん" }
    )
    recorder.finish_example

    side_effect = recorder.examples.first.side_effect_records.first
    expect(side_effect.classification).must_equal "side_effect"
    expect(side_effect.attributes["nickname"]).must_equal "たろちゃん"
    expect(side_effect.caller).wont_be_nil
  end

  it "excludes empty before_context examples from dump hashes" do
    recorder = Tescon::Trace::Recorder.new

    recorder.begin_context_setup(
      id: "spec/models/user_spec.rb:before_context:4",
      file: "spec/models/user_spec.rb",
      line: 4,
      full_description: "User [before_all setup]"
    )
    recorder.end_context_setup(context_id: "spec/models/user_spec.rb:before_context:4")

    recorder.begin_context_setup(
      id: "spec/models/user_spec.rb:before_context:20",
      file: "spec/models/user_spec.rb",
      line: 20,
      full_description: "User when active [before_all setup]"
    )
    recorder.enter_factory_call(
      strategy: :create,
      factory_name: :user,
      traits: [],
      overrides: {},
      caller: "spec/models/user_spec.rb:21"
    )
    recorder.exit_factory_call
    recorder.end_context_setup(context_id: "spec/models/user_spec.rb:before_context:20")

    recorder.start_example(
      id: "spec/models/user_spec.rb:30",
      file: "spec/models/user_spec.rb",
      line: 30,
      description: "returns user"
    )
    recorder.finish_example

    hashes = recorder.example_hashes_for_dump
    ids = hashes.map { |hash| hash["id"] }

    expect(ids).wont_include "spec/models/user_spec.rb:before_context:4"
    expect(ids).must_include "spec/models/user_spec.rb:before_context:20"
    expect(ids).must_include "spec/models/user_spec.rb:30"

    it_hash = hashes.find { |hash| hash["id"] == "spec/models/user_spec.rb:30" }
    expect(it_hash["inherited_setup"]).must_equal(
      [{ "from" => "spec/models/user_spec.rb:before_context:20" }]
    )
  end
end
