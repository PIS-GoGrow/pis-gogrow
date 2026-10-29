# frozen_string_literal: true

module OrderModifiedHelpers
  # Al modificar un pedido se abre un modal sobre la pantalla de edición; "Listo"
  # lleva a Mis pedidos.
  def confirm_order_modified
    within("[role=dialog]", text: "Pedido modificado") do
      click_button "Listo"
    end

    expect(page).to have_current_path(orders_path)
  end
end

RSpec.configure do |config|
  config.include OrderModifiedHelpers, type: :system
end
