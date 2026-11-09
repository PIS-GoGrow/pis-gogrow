# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::OrderSerializer do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders

  describe "#date" do
    it "returns the delivery date as an ISO string" do
      order = orders(:upcoming_confirmed_future)

      serialized = described_class.new(order).to_h

      expect(serialized["date"]).to eq(order.schedule.date.iso8601)
    end

    it "returns nil when the order has no schedule" do
      serialized = described_class.new(orders(:history_without_schedule)).to_h

      expect(serialized["date"]).to be_nil
    end
  end

  describe "other attributes" do
    it "serializes the expected order details" do
      order = orders(:upcoming_pending_today)
      serialized = described_class.new(order).to_h

      expect(serialized).to include(
        "id" => order.id,
        "status" => "pending",
        "amount" => 1,
        "price" => 300.5,
        "consumer_name" => "Test User",
        "consumer_company" => "GoGrow",
        "menu_name" => "Milanesa con papas fritas",
        "address" => "Julio Herrera y Reissig 565",
        "delivery_method" => "home",
        "date" => Date.current.iso8601,
        "time" => order.created_at.strftime("%H:%M")
      )
    end
  end
end
