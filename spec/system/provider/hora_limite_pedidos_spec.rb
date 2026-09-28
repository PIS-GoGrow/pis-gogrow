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

  def saved_deadline
    provider.reload.order_deadline&.strftime("%H:%M")
  end

  before do
    provider.update!(order_deadline: nil)
    sign_in provider_user, role: :provider
  end

  it "reaches the closing time from the account screen" do
    visit provider_account_path
    click_on "Configuración operativa"

    expect(page).to have_current_path(provider_operational_settings_path)
    expect(page).to have_button("Agregar hora de cierre")
  end

  it "adds a deadline and keeps it after a reload and a new session" do
    configure_order_deadline("18:30")

    expect(saved_deadline).to eq("18:30")

    visit provider_operational_settings_path
    expect(page).to have_button("Hora de cierre", text: "18:30")

    sign_out
    sign_in provider_user, role: :provider
    visit provider_operational_settings_path
    expect(page).to have_button("Hora de cierre", text: "18:30")
  end

  it "replaces a deadline with a new one" do
    configure_order_deadline("18:30")

    configure_order_deadline("09:15")

    expect(saved_deadline).to eq("09:15")
    expect(page).to have_no_button("Agregar hora de cierre")
  end

  it "cancels adding a deadline without saving it" do
    visit provider_operational_settings_path
    click_on "Agregar hora de cierre"
    click_on "Cancelar"

    expect(page).to have_button("Agregar hora de cierre")
    expect(saved_deadline).to be_nil
  end

  it "only changes the signed-in provider's deadline" do
    other = providers(:endulzate)
    other.update!(order_deadline: Time.zone.parse("11:00"))

    configure_order_deadline("18:30")

    expect(other.reload.order_deadline.strftime("%H:%M")).to eq("11:00")
  end

  it "does not let a consumer reach the closing time screen" do
    sign_out
    sign_in users(:one), role: :consumer

    visit provider_operational_settings_path

    expect(page).to have_no_current_path(provider_operational_settings_path)
    expect(page).to have_no_content("Hora de cierre")
  end

  it "sends a visitor without a session to sign in" do
    sign_out

    visit provider_operational_settings_path

    expect(page).to have_current_path(sign_in_path)
  end
end
