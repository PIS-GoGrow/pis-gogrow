# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeliveredOrdersSyncJob, type: :job do
  fixtures :users, :companies, :consumers, :providers

  let(:consumer) { consumers(:one) }
  let(:menu) { providers(:office_provider).menus.create!(name: "Wok", description: "De verduras", price: 400) }

  def order_for(date)
    Order.create!(
      consumer:, schedule: menu.schedules.create!(date:, amount: 10), amount: 1, price: 400, discounted_price: 250,
      delivery_method: :office, status: :confirmed
    )
  end

  it "suma a las cuentas los pedidos confirmados que se entregan hoy" do
    travel_to Time.zone.local(2026, 11, 3, 12)
    today = order_for(Date.new(2026, 11, 5))
    later = order_for(Date.new(2026, 11, 6))

    travel_to Time.zone.local(2026, 11, 5, 0, 5)
    described_class.perform_now

    expect(today.accounts.map { it.reload.amount }).to contain_exactly(250, 150)
    expect(later.accounts.map { it.reload.amount }).to contain_exactly(250, 150)

    travel_to Time.zone.local(2026, 11, 6, 0, 5)
    described_class.perform_now

    expect(later.accounts.map { it.reload.amount }).to contain_exactly(500, 300)
  end
end
