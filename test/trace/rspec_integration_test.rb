# frozen_string_literal: true

require "test_helper"
require_relative "../support/trace_stubs"
require "tescon/trace/rspec"

describe Tescon::Trace::RSpec do
  before do
    Tescon::Trace.reset!
  end

  it "builds context setup id from metadata" do
    metadata = {
      file_path: "spec/models/user_spec.rb",
      line_number: 4,
      full_description: "User"
    }

    expect(Tescon::Trace::RSpec.context_setup_id(metadata))
      .must_equal "spec/models/user_spec.rb:before_context:4"
  end

  it "runs before(:context) hook without NoMethodError" do
    example_group_class = Class.new do
      def self.metadata
        {
          file_path: "spec/models/user_spec.rb",
          line_number: 4,
          full_description: "User"
        }
      end
    end

    example_group_class.new.instance_exec do
      metadata = self.class.metadata
      Tescon::Trace.recorder.begin_context_setup(
        id: Tescon::Trace::RSpec.context_setup_id(metadata),
        file: metadata[:file_path],
        line: metadata[:line_number],
        full_description: "#{metadata[:full_description]} [before_all setup]"
      )
    end

    example_group_class.new.instance_exec do
      metadata = self.class.metadata
      Tescon::Trace.recorder.end_context_setup(
        context_id: Tescon::Trace::RSpec.context_setup_id(metadata)
      )
    end

    setup = Tescon::Trace.recorder.examples.first
    expect(setup.role).must_equal "before_context"
    expect(setup.id).must_equal "spec/models/user_spec.rb:before_context:4"
  end
end
