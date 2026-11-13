# frozen_string_literal: true

require "rails_helper"

RSpec.describe UnansweredOrdersRejectionJob, type: :job do
  fixtures :users, :companies, :consumers, :providers

  let(:provider) { providers(:office_provider) }
  let(:menu) { provider.menus.create!(name: "Wok", description: "De verduras", price: 400) }

  def order_for(date, status: :pending)
    Order.create!(
      consumer: consumers(:one), schedule: menu.schedules.find_or_create_by!(date:), amount: 1, price: 400, discounted_price: 250,
      delivery_method: :office, status:
    )
  end

  before do
    provider.update!(order_deadline: "12:00")
    travel_to Time.zone.local(2026, 11, 5, 9)
  end

  it "rechaza los pedidos pendientes de hoy media hora después del cierre del proveedor" do
    pending_today = order_for(Date.new(2026, 11, 5))
    confirmed_today = order_for(Date.new(2026, 11, 5), status: :confirmed)
    pending_tomorrow = order_for(Date.new(2026, 11, 6))

    travel_to Time.zone.local(2026, 11, 5, 12, 30)
    described_class.perform_now

    expect(pending_today.reload).to be_rejected
    expect(pending_today).to be_rejection_reason_no_response
    expect(confirmed_today.reload).to be_confirmed
    expect(pending_tomorrow.reload).to be_pending
  end

  it "no toca los pedidos mientras el proveedor todavía puede responder" do
    order = order_for(Date.new(2026, 11, 5))

    travel_to Time.zone.local(2026, 11, 5, 12, 29)
    described_class.perform_now

    expect(order.reload).to be_pending
  end

  it "no toca los pedidos de un proveedor sin hora de cierre" do
    order = order_for(Date.new(2026, 11, 5))
    provider.update!(order_deadline: nil)

    travel_to Time.zone.local(2026, 11, 5, 18)
    described_class.perform_now

    expect(order.reload).to be_pending
  end

  it "está programado para correr cada minuto en producción" do
    config = YAML.safe_load(Rails.root.join("config/recurring.yml").read).dig("production", "unanswered_orders_rejection")

    expect(config).to eq("class" => "UnansweredOrdersRejectionJob", "schedule" => "every minute")
  end
end
