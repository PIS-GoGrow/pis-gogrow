# frozen_string_literal: true

require "rails_helper"

RSpec.describe SimplifiedOrderSerializer do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders

  let(:order) { orders(:upcoming_confirmed_future) }

  describe "#to_h" do
    it "serializes the order with date formatted from delivery_date as DD/MM/YY" do
      serialized = described_class.new(order).to_h

      expect(serialized).to eq(
        "id" => order.id,
        "amount" => order.amount,
        "price" => order.discounted_price.to_f,
        "date" => order.delivery_date.strftime("%d/%m/%y"),
        "menu_name" => order.menu_name
      )
    end

    it "formats date from delivery_date when delivery_date differs from created_at" do
      delivery = Date.current + 10.days
      order.update_columns(delivery_date: delivery, created_at: delivery - 3.days)

      serialized = described_class.new(order).to_h

      expect(serialized["date"]).to eq(delivery.strftime("%d/%m/%y"))
    end

    it "retains delivery_date when schedule is nil" do
      delivery = Date.current + 4.days
      order.update_columns(schedule_id: nil, delivery_date: delivery, menu_name: "Plato del día")

      serialized = described_class.new(order).to_h

      expect(serialized["date"]).to eq(delivery.strftime("%d/%m/%y"))
      expect(serialized["menu_name"]).to eq("Plato del día")
    end

    it "returns nil for date without error when delivery_date is nil" do
      order = orders(:history_without_schedule)
      order.update_columns(delivery_date: nil)

      serialized = described_class.new(order).to_h

      expect(serialized["date"]).to be_nil
    end

    it "falls back price to base price when discounted_price is nil" do
      order.update_columns(discounted_price: nil)

      serialized = described_class.new(order).to_h

      expect(serialized["price"]).to eq(order.price.to_f)
    end
  end
end
