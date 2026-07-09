# frozen_string_literal: true

require "test_helper"
require "tescon/trace/recorder"

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
      caller: "association"
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
    expect(order_call.records.map(&:model)).must_equal %w[Order]
    expect(order_call.records.first.classification).must_equal "setup"

    user_call = recorder.examples.first.factory_calls[1]
    expect(user_call.records.map(&:model)).must_equal %w[User]
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
end
