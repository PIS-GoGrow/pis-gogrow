# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Flujo de comprobantes múltiples y rechazo por pago parcial", type: :system do
  fixtures :users, :consumers, :companies, :providers

  let(:employee_user) { users(:one) }
  let(:consumer) { consumers(:one) }
  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }
  let(:closed_month) { Date.current.prev_month.beginning_of_month }

  def receipt_file
    Rails.root.join("public/icon.png").to_s
  end

  def create_closed_month_order
    travel_to(Time.zone.local(closed_month.year, closed_month.month, 10, 12)) do
      menu = Menu.create!(provider:, name: "Milanesa con puré", description: "Clásica", price: 500)
      schedule = Schedule.create!(menu:, date: closed_month + 12, amount: 20)

      Order.create!(
        consumer:, schedule:,
        amount: 1, price: 500, discounted_price: 250,
        delivery_method: :office, status: :confirmed
      )
    end
  end

  before do
    consumer.orders.destroy_all
    consumer.accounts.destroy_all
    provider.accounts.where(month: closed_month).destroy_all
    create_closed_month_order
  end

  it "permite rechazar por pago parcial, ver el aviso correspondiente, reenviar otro comprobante y revisarlo" do
    # 1. El empleado ingresa y sube el primer comprobante
    sign_in employee_user, role: :consumer
    visit accounts_path

    within("[role=tabpanel]") do
      expect(page).to have_button("Subir comprobante de pago")
      click_on "Subir comprobante de pago"
    end

    within(find("[role=dialog]")) do
      attach_file("Seleccionar archivo", receipt_file)
      click_on "Subir comprobante de pago"
    end

    expect(page).to have_content(I18n.t("pages.accounts.show.receipt_success_description"))
    within("[role=tabpanel]") do
      expect(page).to have_content("Enviado")
    end

    # 2. El proveedor revisa el primer comprobante y lo rechaza con 'El pago es parcial'
    sign_out
    sign_in provider_user, role: :provider
    visit provider_collections_path

    month_card = find("[data-slot=card]", text: I18n.l(closed_month, format: :month_name_year))
    within(month_card) { click_on "Empleados" }
    click_on employee_user.name

    click_on "Revisar pago"
    within(find("[role=dialog]")) { click_on "Rechazar" }

    within(find("[role=dialog]", text: "Rechazar comprobante")) do
      find("label", text: "El pago es parcial").click
      click_on "Rechazar comprobante"
    end

    expect(page).to have_content("Pago parcial registrado")
    click_on "Listo"

    # 3. El empleado vuelve a ingresar y ve la advertencia de pago parcial en vez del cartel rojo genérico
    sign_out
    sign_in employee_user, role: :consumer
    visit accounts_path

    within("[role=tabpanel]") do
      expect(page).to have_content("Rechazado")
      expect(page).to have_content(I18n.t("pages.accounts.show.partial_payment_warning"))
      expect(page).to have_no_content("La imagen está borrosa")
    end

    # 4. El empleado sube un segundo comprobante y la advertencia de pago parcial desaparece
    within("[role=tabpanel]") do
      click_on "Subir comprobante de pago"
    end

    within(find("[role=dialog]")) do
      attach_file("Seleccionar archivo", receipt_file)
      click_on "Subir comprobante de pago"
    end

    expect(page).to have_content(I18n.t("pages.accounts.show.receipt_success_description"))
    within("[role=tabpanel]") do
      expect(page).to have_content("Enviado")
      expect(page).to have_no_content(I18n.t("pages.accounts.show.partial_payment_warning"))
    end

    # 5. El proveedor vuelve a Cobros pendientes y ve ambos comprobantes en el historial del empleado
    sign_out
    sign_in provider_user, role: :provider
    visit provider_collections_path

    month_card = find("[data-slot=card]", text: I18n.l(closed_month, format: :month_name_year))
    within(month_card) { click_on "Empleados" }
    click_on employee_user.name

    # Se observan ambos comprobantes en el panel desplegado
    expect(page).to have_content("Pago parcial")
    expect(page).to have_button("Revisar pago")

    # 6. El proveedor revisa y aprueba el segundo comprobante
    click_on "Revisar pago"
    within(find("[role=dialog]")) { click_on "Aprobar" }
    expect(page).to have_content("Cobro confirmado")
    click_on "Listo"

    # Para que el período completo pase a Historial, la cuenta de la empresa debe estar saldada
    company_account = consumer.company.accounts.find_by(provider:, month: closed_month)
    if company_account && company_account.collection_status != "approved"
      company_account.payments.create!(provider:, status: :approved)
    end

    # 7. El proveedor consulta la pestaña Historial
    visit provider_collections_path
    find("[role=tab]", text: "Historial").click

    history_card = find("[data-slot=card]", text: I18n.l(closed_month, format: :month_name_year))
    within(history_card) { click_on "Empleados" }
    click_on employee_user.name

    # El historial mantiene la lista visible y permite descargarla completa.
    expect(page).to have_button("Descargar comprobantes")

    # Al desplegarlo muestra ambos comprobantes con botón de descarga individual
    expect(page).to have_content("Pago parcial")
    expect(page).to have_css("a[download]", minimum: 2)
  end
end
