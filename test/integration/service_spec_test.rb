# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../integration_helper"

describe "typical service object spec" do
  it "converts hooks and eq while leaving change / have_received matchers unchanged" do
    source = <<~RUBY
      require "rails_helper"

      RSpec.describe Orders::Cancel do
        describe ".call" do
          subject(:result) { described_class.call(order) }

          let(:order) { create(:order, status: :pending) }

          before(:each) do
            allow(Notifier).to receive(:deliver)
          end

          context "when the order is already shipped" do
            let(:order) { create(:order, status: :shipped) }

            it "returns failure without notifying" do
              expect(result).not_to be_success
              expect(Notifier).not_to have_received(:deliver)
            end
          end

          context "when cancellation succeeds" do
            it "marks the order cancelled" do
              expect { result }.to change { order.reload.status }.from("pending").to("cancelled")
              expect(result).to be_success
            end
          end
        end
      end
    RUBY

    expected = <<~RUBY
      require "rails_helper"

      describe Orders::Cancel do
        describe ".call" do
          let(:result) { described_class.call(order) }

          let(:order) { create(:order, status: :pending) }

          before do
            allow(Notifier).to receive(:deliver)
          end

          describe "when the order is already shipped" do
            let(:order) { create(:order, status: :shipped) }

            it "returns failure without notifying" do
              expect(result).not_to be_success
              expect(Notifier).not_to have_received(:deliver)
            end
          end

          describe "when cancellation succeeds" do
            it "marks the order cancelled" do
              expect { result }.to change { order.reload.status }.from("pending").to("cancelled")
              expect(result).to be_success
            end
          end
        end
      end
    RUBY

    assert_converts source, expected, path: "spec/services/orders/cancel_spec.rb"
  end
end
