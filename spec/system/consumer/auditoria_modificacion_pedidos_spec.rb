# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auditoría de modificación de pedidos", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus, :schedules, :orders

  let(:order) { orders(:upcoming_pending_future) }

  before do
    page.current_window.resize_to(1400, 1400)
    sign_in users(:one), role: :consumer
  end

  it "registra en audit_logs los valores anteriores y nuevos al editar un pedido y no al cancelar" do
    visit_hydrated order_path(order)

    click_button "Editar"
    within("[role=dialog]") do
      click_button "Agregar uno"
      fill_in "notes", with: "Sin cebolla"
      click_button "Guardar cambios"
    end

    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.1 until order.reload.audit_logs.exists?
    end

    log = order.audit_logs.sole
    expect(log.user).to eq(users(:one))
    expect(log.changeset).to include(
      "amount" => [ 1, 2 ],
      "notes" => [ nil, "Sin cebolla" ]
    )
    expect(log.created_at).to be_present

    click_button "Cancelar"
    within("[role=dialog]") do
      click_button "Cancelar pedido"
    end

    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.1 until order.reload.cancelled?
    end

    expect(order.audit_logs.count).to eq(1)
  end
end
