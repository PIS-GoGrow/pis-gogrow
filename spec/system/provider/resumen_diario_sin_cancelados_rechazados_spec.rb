# frozen_string_literal: true

require "rails_helper"

# Regresión del defecto B2: el resumen diario de Proveedor → Pedidos sumaba
# viandas y monto de todos los pedidos, incluidos los cancelados y rechazados.
# Los pedidos siguen listados, pero no aportan al resumen del día.
RSpec.describe "Resumen diario del proveedor sin cancelados ni rechazados", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders

  let(:provider_user) { users(:provider_user) }
  let(:schedule) { schedules(:future) }
  let(:day) { schedule.date }
  let(:day_label) { "Día: #{DateFormat.short(day)}" }

  before do
    Order.destroy_all

    @confirmed = Array.new(3) do
      create_order(status: :confirmed)
    end
    @rejected = create_order(status: :rejected, rejection_reason: :out_of_stock)
    @cancelled = create_order(status: :cancelled)

    page.current_window.resize_to(1400, 1400)
    sign_in provider_user, role: :provider
  end

  def create_order(status:, rejection_reason: nil)
    Order.create!(
      consumer: consumers(:one),
      schedule:,
      status:,
      delivery_method: :office,
      amount: 1,
      price: 300.50,
      discounted_price: 150.25,
      rejection_reason:
    )
  end

  it "cuenta solo pendientes y confirmados y deja visibles los demás" do
    visit_hydrated provider_orders_path
    without_animations

    expect(page).to have_css(
      "button",
      text: "#{day_label} | Viandas: 3 | Monto: $901,50"
    )

    click_button day_label

    @confirmed.each do |order|
      within(provider_order_card(order)) do
        expect(page).to have_content("Confirmado")
      end
    end

    within(provider_order_card(@rejected)) do
      expect(page).to have_content("Rechazado")
    end
    within(provider_order_card(@cancelled)) do
      expect(page).to have_content("Cancelado")
    end

    # Los tres pedidos que no cuentan siguen en la lista del día.
    expect(page).to have_css(provider_order_card(@rejected))
    expect(page).to have_css(provider_order_card(@cancelled))
  end
end
