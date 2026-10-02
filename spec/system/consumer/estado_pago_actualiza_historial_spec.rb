# frozen_string_literal: true

require "rails_helper"

# Historia IBP-020: "Como EMPLEADO, quiero consultar mi historial de pagos y sus
# estados para mantener un registro de mis gastos."
#
# Criterio 3: "Los cambios de estado realizados por el proveedor se reflejan sin
# alterar el historial anterior". El estado de un pago lo cambia el proveedor
# desde /provider/collections, así que este archivo recorre el circuito completo --
# el empleado sube el comprobante, el proveedor lo aprueba o lo rechaza, y el
# empleado vuelve a su historial en /accounts -- en vez de dar por hecho el
# estado final con datos armados a mano.
#
# El pago aprobado manda la cuenta al historial (Account.history son las cuentas
# con un pago aprobado) y el rechazado la deja en pendientes, con el motivo. En
# los dos casos el pago del mes anterior tiene que seguir intacto.
RSpec.describe "El cambio de estado de un pago hecho por el proveedor" do
  fixtures :users, :consumers, :companies, :providers

  def receipt_file
    Rails.root.join("public/icon.png").to_s
  end

  # Ver consultar_historial_de_pagos_spec.rb: la cuenta la crea y la sincroniza
  # Order#assign_account, así que se viaja al mes wanted para que caiga en ese mes.
  def confirmed_order(consumer:, provider:, month:, quantity:, discounted_price:)
    travel_to(Time.zone.local(month.year, month.month, month.day, 12)) do
      menu = Menu.create!(provider:, name: "Milanesa al pan", description: "Con papas", price: 1000)
      schedule = Schedule.create!(menu:, date: month + 7, amount: 20)

      Order.create!(
        consumer:, schedule:,
        amount: quantity, price: 1000 * quantity, discounted_price:,
        delivery_method: :office, status: :confirmed
      )
    end
  end

  before do
    consumers(:one).orders.destroy_all
    consumers(:one).accounts.destroy_all
  end

  # Un mes ya pagado y cerrado: es el historial anterior que no se debe tocar.
  def previous_payment(consumer:, provider:, month:, discounted_price:)
    confirmed_order(
      consumer:, provider:, month:, quantity: 1, discounted_price:
    )
    account = consumer.accounts.find_by!(provider:, month: month.beginning_of_month)
    payment = account.payments.build(provider:, status: :approved)
    payment.receipt.attach(
      io: StringIO.new(File.binread(Rails.root.join("public/icon.png"))),
      filename: "comprobante-anterior.png", content_type: "image/png"
    )
    payment.save!
    payment
  end

  def employee
    users(:one)
  end

  def provider_user
    users(:provider_user)
  end

  def month_label(month)
    I18n.l(month, format: :month_year)
  end

  let(:provider) { providers(:tuviandita) }
  let(:previous_month) { Date.current.change(day: 15).months_ago(1) }
  let(:current_month) { Date.current.beginning_of_month }

  # El circuito del empleado: entra a /accounts, sube el comprobante de la cuenta
  # del mes corriente y la ve quedar "Enviada".
  def employee_submits_receipt
    sign_in employee

    visit accounts_path
    within(find("[role=tabpanel]")) do
      expect(page).to have_button("Subir comprobante de pago")
      click_on "Subir comprobante de pago"
    end

    within(find("[role=dialog]")) do
      attach_file("Seleccionar archivo", receipt_file)
      click_on "Subir comprobante de pago"
    end

    expect(page).to have_content(I18n.t("pages.accounts.show.receipt_success_description"))
    within(find("[role=tabpanel]")) do
      expect(page).to have_content("Enviado")
    end
  end

  it "shows an error notification and saves nothing when the receipt format is invalid" do
    confirmed_order(
      consumer: consumers(:one), provider:, month: current_month,
      quantity: 2, discounted_price: 300
    )
    sign_in employee

    visit accounts_path
    within(find("[role=tabpanel]")) { click_on "Subir comprobante de pago" }
    within(find("[role=dialog]")) do
      attach_file("Seleccionar archivo", Rails.root.join("public/robots.txt"), make_visible: true)
      click_on "Subir comprobante de pago"
    end

    expect(page).to have_content(I18n.t("pages.accounts.show.receipt_error_title"))
    expect(page).to have_content(I18n.t("pages.accounts.show.receipt_error_description"))
    expect(page).to have_button(I18n.t("pages.accounts.show.receipt_error_action"))
    expect(consumers(:one).accounts.find_by!(provider:).payments).to be_empty
  end

  # Criterio 3 -- aprobado
  it "moves the account to the history once the provider approves, leaving the previous payment untouched" do
    previous_payment(
      consumer: consumers(:one), provider:, month: previous_month,
      discounted_price: 500
    )
    confirmed_order(
      consumer: consumers(:one), provider:, month: current_month,
      quantity: 2, discounted_price: 300
    )
    employee_submits_receipt

    sign_out
    sign_in provider_user, role: :provider
    visit provider_collections_path

    # La cuenta del empleado vive dentro del grupo "Empleados", colapsado por
    # defecto: hay que desplegarlo para llegar a su fila.
    click_on "Empleados"

    # Consistencia entre vistas: el importe que el proveedor aprueba es el mismo
    # que el empleado tiene en su cuenta, no dos cálculos distintos.
    expect(page).to have_content(users(:one).name)
    click_on users(:one).name
    expect(page).to have_content("300")

    # El botón de Aprobar vive dentro del sheet del comprobante: hay que
    # abrirlo primero (PaymentReviewSheet), al que se entra por "Revisar pago"
    # desde la fila del empleado.
    click_on "Revisar pago"
    within(find("[role=dialog]")) { click_on "Aprobar" }
    expect(page).to have_content(I18n.t("flash.payment_approved"))

    sign_out
    sign_in employee
    visit accounts_path
    within(find("[role=tabpanel]")) do
      expect(page).to have_no_content("Enviado")
    end

    find("[role=tab]", text: "Historial").click
    within(find("[role=tabpanel]")) do
      expect(page).to have_content(month_label(current_month))
      expect(page).to have_content(month_label(previous_month))
      expect(page).to have_content("Aceptado", count: 2)
      # El mes anterior conserva su propio importe: el pago nuevo no lo pisa.
      expect(page).to have_content("$300")
      expect(page).to have_content("$500")
    end
  end

  # Criterio 3 -- rechazado
  it "keeps the account pending with the reason when the provider rejects, leaving the previous payment untouched" do
    previous_payment(
      consumer: consumers(:one), provider:, month: previous_month,
      discounted_price: 500
    )
    confirmed_order(
      consumer: consumers(:one), provider:, month: current_month,
      quantity: 2, discounted_price: 300
    )
    employee_submits_receipt

    sign_out
    sign_in provider_user, role: :provider
    visit provider_collections_path

    # La cuenta del empleado vive dentro del grupo "Empleados", colapsado por
    # defecto: hay que desplegarlo para llegar a su fila.
    click_on "Empleados"
    click_on users(:one).name

    # Mismo motivo que en el caso de arriba: primero hay que abrir el
    # comprobante para llegar al botón de Rechazar, que abre a su vez el
    # diálogo de motivo. Los dos quedan abiertos a la vez (role=dialog
    # matchea ambos), así que el segundo find se desambigua por texto.
    click_on "Revisar pago"
    within(find("[role=dialog]")) { click_on "Rechazar" }
    within(find("[role=dialog]", text: "Rechazar comprobante")) { click_on "Rechazar comprobante" }
    expect(page).to have_content(I18n.t("flash.payment_rejected"))

    sign_out
    sign_in employee
    visit accounts_path

    within(find("[role=tabpanel]")) do
      expect(page).to have_content("Rechazado")
      expect(page).to have_content("La imagen está borrosa")
    end

    find("[role=tab]", text: "Historial").click
    within(find("[role=tabpanel]")) do
      expect(page).to have_content(month_label(previous_month))
      expect(page).to have_content("$500")
      expect(page).to have_content("Aceptado", count: 1)
      # Un pago rechazado no entra al historial: sigue siendo deuda pendiente.
      expect(page).to have_no_content(month_label(current_month))
    end
  end
end
