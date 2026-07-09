# frozen_string_literal: true

module ActiveRecord
  class Base
    class << self
      attr_accessor :sequence

      def table_name
        @table_name
      end

      def table_name=(value)
        @table_name = value
      end

      def allocate_id
        self.sequence ||= 0
        self.sequence += 1
      end
    end

    attr_reader :attributes

    def initialize(attributes = {})
      @attributes = attributes.transform_keys(&:to_s)
      @persisted = false
    end

    def id
      @attributes["id"]
    end

    def persisted?
      @persisted
    end

    def save
      _create_record
      self
    end

    def _create_record(*)
      record_id = self.class.allocate_id
      @attributes["id"] = record_id
      @persisted = true
      true
    end
  end
end

class User < ActiveRecord::Base
  self.table_name = "users"
end

class Order < ActiveRecord::Base
  self.table_name = "orders"
end

module FactoryBot
  module Syntax
    module Methods
      def create(factory_name, *args, **kwargs)
        FactoryBot.create(factory_name, *args, **kwargs)
      end

      def create_list(factory_name, count, *args, **kwargs)
        FactoryBot.create_list(factory_name, count, *args, **kwargs)
      end
    end
  end

  module_function

  def create(factory_name, *args, **kwargs)
    traits = args.select { |arg| arg.is_a?(Symbol) }
    overrides = args.find { |arg| arg.is_a?(Hash) } || {}
    overrides = overrides.merge(kwargs).transform_keys(&:to_s)

    case factory_name
    when :user
      User.new(overrides).save
    when :order
      status = traits.include?(:paid) ? "paid" : "pending"
      Order.new(overrides.merge("status" => status)).save
    end
  end

  def create_list(factory_name, count, *args, **kwargs)
    Array.new(count) { create(factory_name, *args, **kwargs) }
  end

  extend Syntax::Methods
end
