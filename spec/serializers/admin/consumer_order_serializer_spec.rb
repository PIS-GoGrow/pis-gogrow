# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ConsumerOrderSerializer do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders

  let(:order) { orders(:upcoming_confirmed_future) }

  describe "#to_h" do
    it "serializes the order with date formatted from delivery_date" do
      serialized = described_class.new(order).to_h

      expect(serialized).to eq(
        "id" => order.id,
        "amount" => order.amount,
        "provider_id" => order.provider_id,
        "date" => order.delivery_date.strftime("%-d/%-m"),
        "provider_name" => order.schedule.menu.provider.user.name,
        "subsidy" => (order.price - order.discounted_price).to_f,
        "charged" => order.discounted_price.to_f
      )
    end

    it "formats date from delivery_date when delivery_date differs from created_at" do
      delivery = Date.current + 10.days
      order.update_columns(delivery_date: delivery, created_at: delivery - 4.days)

      serialized = described_class.new(order).to_h

      expect(serialized["date"]).to eq(delivery.strftime("%-d/%-m"))
    end

    it "retains delivery_date when schedule is nil" do
      delivery = Date.current + 5.days
      order.update_columns(schedule_id: nil, delivery_date: delivery)

      serialized = described_class.new(order).to_h

      expect(serialized["date"]).to eq(delivery.strftime("%-d/%-m"))
      expect(serialized["provider_id"]).to eq(order.provider_id)
      expect(serialized["provider_name"]).to be_nil
    end

    it "falls back to created_at for date without error when delivery_date is nil" do
      order = orders(:history_without_schedule)
      order.update_columns(delivery_date: nil)

      serialized = described_class.new(order).to_h

      expect(serialized["date"]).to eq(order.created_at.strftime("%-d/%-m"))
    end

    it "falls back charged to price when discounted_price is nil" do
      order.update_columns(discounted_price: nil)

      serialized = described_class.new(order).to_h

      expect(serialized["charged"]).to eq(order.price.to_f)
      expect(serialized["subsidy"]).to eq(0.0)
    end
  end
end
