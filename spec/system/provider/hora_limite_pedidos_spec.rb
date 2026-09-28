# frozen_string_literal: true

# TODO(integración): falta implementar el visualizador del tiempo restante para el
# cierre de recepción de pedidos (criterios 1, 3 y 4 del lado del proveedor) antes
# de poder testear que el proveedor ve el tiempo restante, que se actualiza solo y
# que al llegar al límite muestra "recepción cerrada" en vez de un tiempo negativo.
# Queda para IBP-067, que es la historia dueña de esa pantalla; no asumir
# /provider/dashboard como ubicación. Historia: "Como PROVEEDOR, quiero ver cuánto
# tiempo falta para el cierre de recepción de pedidos".

require "rails_helper"

RSpec.describe "Hora límite de pedidos del proveedor" do
  fixtures :users, :providers, :consumers, :companies

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }

  def order_deadline_select
    find('[role="combobox"][aria-label="Hora de cierre"]')
  end

  def add_deadline(value)
    click_on "Agregar hora de cierre"
    find("#order_deadline").click
    find('[role="option"]', text: value).click
    click_on "Guardar cambios"
    expect(page).to have_content("¡Hora de cierre guardada!")
    click_on "Listo"
  end

  def update_deadline(value)
    order_deadline_select.click
    find('[role="option"]', text: value).click
  end

  before do
    sign_in provider_user, role: :provider
    visit provider_operational_settings_path
  end

  it "saves a new deadline and keeps it after a reload and a new session" do
    add_deadline("18:30")

    expect(order_deadline_select).to have_text("18:30")
    expect(provider.reload.order_deadline.strftime("%H:%M")).to eq("18:30")

    visit provider_operational_settings_path
    expect(order_deadline_select).to have_text("18:30")

    sign_out
    sign_in provider_user, role: :provider
    visit provider_operational_settings_path
    expect(order_deadline_select).to have_text("18:30")
  end

  it "replaces a deadline with a new one" do
    add_deadline("18:30")

    update_deadline("09:15")

    expect(order_deadline_select).to have_text("09:15")
    expect(provider.reload.order_deadline.strftime("%H:%M")).to eq("09:15")
  end

  it "does not let a consumer reach the deadline screen" do
    sign_out
    sign_in users(:one), role: :consumer

    visit provider_operational_settings_path

    expect(page).to have_no_current_path(provider_operational_settings_path)
  end

  it "sends a visitor without a session to sign in" do
    sign_out

    visit provider_operational_settings_path

    expect(page).to have_current_path(sign_in_path)
  end
end
