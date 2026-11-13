# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::CollectionOrderSerializer do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders

  let(:order) { orders(:upcoming_confirmed_future) }

  describe "#to_h" do
    it "serializes the collection order with delivery_date formatted as DD/MM/YY" do
      serialized = described_class.new(order).to_h

      expect(serialized).to eq(
        "id" => order.id,
        "amount" => order.amount,
        "menu_name" => order.menu_name.to_s,
        "consumer_name" => order.consumer.user.name,
        "delivery_date" => order.delivery_date.strftime("%d/%m/%y"),
        "charged" => order.discounted_price.to_f,
        "subsidy" => (order.price - order.discounted_price).to_f
      )
    end

    it "formats delivery_date correctly when delivery_date differs from created_at" do
      delivery = Date.current + 7.days
      order.update_columns(delivery_date: delivery, created_at: delivery - 5.days)

      serialized = described_class.new(order).to_h

      expect(serialized["delivery_date"]).to eq(delivery.strftime("%d/%m/%y"))
    end

    it "retains delivery_date when schedule is nil" do
      delivery = Date.current + 3.days
      order.update_columns(schedule_id: nil, delivery_date: delivery, menu_name: "Ensalada César")

      serialized = described_class.new(order).to_h

      expect(serialized["delivery_date"]).to eq(delivery.strftime("%d/%m/%y"))
      expect(serialized["menu_name"]).to eq("Ensalada César")
    end

    it "returns nil for delivery_date without error when delivery_date is nil" do
      order = orders(:history_without_schedule)
      order.update_columns(delivery_date: nil)

      serialized = described_class.new(order).to_h

      expect(serialized["delivery_date"]).to be_nil
    end

    it "falls back charged to price and subsidy to 0.0 when discounted_price is nil" do
      order.update_columns(discounted_price: nil)

      serialized = described_class.new(order).to_h

      expect(serialized["charged"]).to eq(order.price.to_f)
      expect(serialized["subsidy"]).to eq(0.0)
    end
  end
end
