# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Importe esperado del comprobante y saldo pendiente (B4)", type: :system do
  fixtures :users, :consumers, :companies, :providers

  let(:employee_user) { users(:one) }
  let(:consumer) { consumers(:one) }
  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }
  let(:closed_month) { Date.current.prev_month.beginning_of_month }

  def receipt_file
    Rails.root.join("public/icon.png").to_s
  end

  def create_closed_month_order(amount: 290.25)
    travel_to(Time.zone.local(closed_month.year, closed_month.month, 10, 12)) do
      menu = Menu.create!(provider:, name: "Menú B4", description: "Plato", price: amount)
      schedule = Schedule.create!(menu:, date: Date.current)

      Order.create!(
        consumer:, schedule:,
        amount: 1, price: amount, discounted_price: amount,
        delivery_method: :office, status: :confirmed
      )
    end
  end

  before do
    provider.update!(
      bank_name: "Santander",
      bank_account_details: "Cuenta: 1150260\nMoneda: UYU",
      beneficiary: "Tu Viandita S.A."
    )
    consumer.orders.destroy_all
    consumer.accounts.destroy_all
    provider.accounts.where(month: closed_month).destroy_all
    create_closed_month_order(amount: 290.25)
  end

  it "conserva el importe esperado en revisión aunque aumente la deuda, y permite saldar el resto tras aprobar" do
    # 1. El empleado ingresa y sube el comprobante con la deuda inicial ($290,25)
    sign_in employee_user, role: :consumer
    visit_hydrated accounts_path

    within("[role=tabpanel]") do
      expect(page).to have_content("290,25")
      attach_file("Comprobante", receipt_file)
      click_on "Subir comprobante de pago"
    end

    expect(page).to have_content(I18n.t("pages.accounts.show.receipt_success_description"))
    within("[role=tabpanel]") do
      expect(page).to have_content("En revisión")
    end

    # 2. Se genera nueva deuda de $450 para la misma cuenta / período (total pasa a 740,25)
    account = consumer.accounts.find_by!(provider:, month: closed_month)
    account.update!(amount: 740.25)

    # 3. El proveedor revisa el cobro: ve como importe esperado los $290,25 originales
    sign_out
    sign_in provider_user, role: :provider
    visit provider_collections_path

    month_card = find("[data-slot=card]", text: I18n.l(closed_month, format: :month_name_year))
    within(month_card) { click_on "Empleados" }
    click_on employee_user.name

    click_on "Revisar pago"
    within(find("[role=dialog]")) do
      expect(page).to have_content("Importe esperado:")
      expect(page).to have_content("290,25")
      expect(page).to have_no_content("740,25")
      click_on "Confirmar"
    end

    expect(page).to have_content("Cobro aprobado")
    click_on "Listo"

    # 4. El empleado ingresa nuevamente: ve saldo pendiente de $450 y puede enviar un nuevo comprobante
    sign_out
    sign_in employee_user, role: :consumer
    visit_hydrated accounts_path

    within("[role=tabpanel]") do
      expect(page).to have_content("$450")
      expect(page).to have_button("Subir comprobante de pago", disabled: true)
      attach_file("Comprobante", receipt_file)
      click_on "Subir comprobante de pago"
    end

    expect(page).to have_content(I18n.t("pages.accounts.show.receipt_success_description"))
    within("[role=tabpanel]") do
      expect(page).to have_content("En revisión")
    end

    # 5. El proveedor revisa el segundo comprobante y verifica el importe esperado de $450
    sign_out
    sign_in provider_user, role: :provider
    visit provider_collections_path

    month_card = find("[data-slot=card]", text: I18n.l(closed_month, format: :month_name_year))
    within(month_card) { click_on "Empleados" }
    click_on employee_user.name

    click_on "Revisar pago"
    within(find("[role=dialog]")) do
      expect(page).to have_content("Importe esperado:")
      expect(page).to have_content("$450")
    end
  end
end
