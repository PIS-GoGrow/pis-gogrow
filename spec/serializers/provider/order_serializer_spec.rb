# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::OrderSerializer do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders

  describe "#delivery_date" do
    it "returns 'hoy' for orders scheduled for today" do
      order = orders(:upcoming_pending_today)
      serialized = described_class.new(order).to_h

      expect(serialized["delivery_date"]).to eq(I18n.t("pages.provider_orders.index.today"))
    end

    it "returns 'mañana' for orders scheduled for tomorrow" do
      tomorrow_schedule = schedules(:office)
      tomorrow_schedule.update!(date: Date.current + 1.day)
      order = orders(:upcoming_confirmed_future)
      order.update!(schedule: tomorrow_schedule)

      serialized = described_class.new(order).to_h

      expect(serialized["delivery_date"]).to eq(I18n.t("pages.provider_orders.index.tomorrow"))
    end

    it "returns formatted date for orders scheduled further in the future" do
      order = orders(:upcoming_confirmed_future)
      expected_date = order.schedule.date.strftime(I18n.t("pages.provider_orders.index.date"))

      serialized = described_class.new(order).to_h

      expect(serialized["delivery_date"]).to eq(expected_date)
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
        "menu_name" => "Milanesa con papas fritas",
        "address" => "Julio Herrera y Reissig 565",
        "delivery_date" => "hoy",
        "time" => order.created_at.strftime("%H:%M")
      )
    end
  end
end
