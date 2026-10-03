# frozen_string_literal: true

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

  context "when telling the provider since when the change applies" do
    let(:open_today) { "El cambio se aplica desde ahora. Los pedidos cerrarán todos los días a las 13:00." }
    let(:closed_today) do
      "El cambio se aplica desde ahora. La recepción de pedidos de hoy ya está cerrada. " \
        "A partir de mañana, cerrará todos los días a las 11:00."
    end

    around do |example|
      travel_to(Time.current.change(hour: 12)) { example.run }
    end

    def add_deadline(time)
      visit provider_operational_settings_path
      click_on "Agregar hora de cierre"
      find_by_id("order_deadline").click
      choose_time(time)
      click_on "Guardar cambios"
    end

    def change_deadline(time)
      visit provider_operational_settings_path
      find_button("Hora de cierre").click
      choose_time(time)
    end

    it "says a deadline still ahead applies from now on" do
      add_deadline("13:00")

      expect(page).to have_content(open_today)
    end

    it "says today is already closed when the new deadline has passed" do
      add_deadline("11:00")

      expect(page).to have_content(closed_today)
    end

    it "informs since when it applies after changing an existing deadline" do
      provider.update!(order_deadline: Time.zone.parse("13:00"))

      change_deadline("11:00")

      expect(page).to have_content(closed_today)
      expect(saved_deadline).to eq("11:00")
    end

    it "says the change applies from now when moving a passed deadline later" do
      provider.update!(order_deadline: Time.zone.parse("11:00"))

      change_deadline("13:00")

      expect(page).to have_content(open_today)
      expect(saved_deadline).to eq("13:00")
    end
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
