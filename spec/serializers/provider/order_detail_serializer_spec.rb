# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::OrderDetailSerializer do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders

  [
    [ nil, nil ],
    [ 0, 300.50 ],
    [ 300.50, 0 ]
  ].each do |discounted_price, subsidy|
    it "serializes discounted price #{discounted_price.inspect} and subsidy #{subsidy.inspect} without losing zero or null" do
      order = orders(:upcoming_pending_today)
      order.update!(discounted_price:)

      serialized = described_class.new(order.reload).to_h

      expect(serialized).to include(
        "price" => 300.50, "discounted_price" => discounted_price, "subsidy" => subsidy
      )
    end
  end

  it "sends the creation date and time in Montevideo when UTC is already the next day" do
    order = orders(:upcoming_pending_today)
    order.update!(created_at: Time.utc(2026, 10, 16, 1, 15))

    serialized = described_class.new(order.reload).to_h

    expect(serialized).to include("created_on" => "2026-10-15", "time" => "22:15")
  end

  it "serializes missing schedule and legacy selections without inventing data" do
    order = orders(:history_without_schedule)

    serialized = described_class.new(order).to_h

    expect(serialized).to include(
      "date" => nil, "schedule_amount" => nil, "remaining_amount" => nil,
      "menu_option_groups" => [], "selected_options" => []
    )
  end
end
