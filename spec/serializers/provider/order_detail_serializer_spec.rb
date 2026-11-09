# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::OrderDetailSerializer do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders

  it "does not expose what the employee and the company pay nor the dish description" do
    serialized = described_class.new(orders(:upcoming_pending_today)).to_h

    expect(serialized).to include("price" => 300.50)
    expect(serialized).not_to include("discounted_price", "subsidy", "menu_description")
  end

  it "sends the creation date and time in Montevideo when UTC is already the next day" do
    order = orders(:upcoming_pending_today)
    order.update!(created_at: Time.utc(2026, 10, 16, 1, 15))

    serialized = described_class.new(order.reload).to_h

    expect(serialized).to include("created_on" => "2026-10-15", "time" => "10:15 PM")
  end

  it "serializes missing schedule and legacy selections without inventing data" do
    order = orders(:history_without_schedule)

    serialized = described_class.new(order).to_h

    expect(serialized).to include(
      "date" => nil,
      "menu_option_groups" => [], "selected_options" => []
    )
  end
end
