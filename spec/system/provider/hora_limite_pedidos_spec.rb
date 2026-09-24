# frozen_string_literal: true

# TODO(integración): falta implementar el visualizador del tiempo restante para el
# cierre de recepción de pedidos (criterios 1, 3 y 4 del lado del proveedor) antes
# de poder testear que el proveedor ve el tiempo restante, que se actualiza solo y
# que al llegar al límite muestra "recepción cerrada" en vez de un tiempo negativo.
# El cliente todavía no definió en qué pantalla va; no asumir /provider/dashboard.
# Historia: "Como PROVEEDOR, quiero ver cuánto tiempo falta para el cierre de
# recepción de pedidos". Defecto: DEFECT-proveedor-sin-tiempo-restante-cierre-24-09-2026.

require "rails_helper"

RSpec.describe "Hora límite de pedidos del proveedor" do
  fixtures :users, :providers, :consumers, :companies

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }

  def deadline_field
    find_field("Hora límite")
  end

  def save_deadline(value)
    if value.blank?
      page.execute_script("arguments[0].value = ''", deadline_field)
    else
      fill_in "Hora límite", with: Time.zone.parse(value)
    end
    click_on "Guardar"
  end

  before do
    sign_in provider_user, role: :provider
    visit provider_dashboard_path
  end

  it "saves a new deadline and keeps it after a reload and a new session" do
    save_deadline("18:30")

    expect(page).to have_content(I18n.t("flash.order_deadline_updated"))
    expect(deadline_field.value).to eq("18:30")
    expect(provider.reload.order_deadline.strftime("%H:%M")).to eq("18:30")

    visit provider_dashboard_path
    expect(deadline_field.value).to eq("18:30")

    sign_out
    sign_in provider_user, role: :provider
    visit provider_dashboard_path
    expect(deadline_field.value).to eq("18:30")
  end

  it "replaces a deadline with a new one" do
    save_deadline("18:30")
    expect(page).to have_content(I18n.t("flash.order_deadline_updated"))

    save_deadline("09:15")

    expect(page).to have_field("Hora límite", with: "09:15")
    expect(provider.reload.order_deadline.strftime("%H:%M")).to eq("09:15")
  end

  it "clears the deadline to accept orders all day" do
    save_deadline("")

    expect(page).to have_content(I18n.t("flash.order_deadline_updated"))
    expect(deadline_field.value).to eq("")
    expect(provider.reload.order_deadline).to be_nil
  end

  it "does not let a consumer reach the deadline screen" do
    sign_out
    sign_in users(:one), role: :consumer

    visit provider_dashboard_path

    expect(page).to have_no_field("Hora límite")
    expect(page).to have_no_current_path(provider_dashboard_path)
  end

  it "sends a visitor without a session to sign in" do
    sign_out

    visit provider_dashboard_path

    expect(page).to have_current_path(sign_in_path)
  end
end
