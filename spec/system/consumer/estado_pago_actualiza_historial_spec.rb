# frozen_string_literal: true

require "rails_helper"

# Historia IBP-020: "Como EMPLEADO, quiero consultar mi historial de pagos y sus
# estados para mantener un registro de mis gastos."
#
# Criterio 3: "Los cambios de estado realizados por el proveedor se reflejan sin
# alterar el historial anterior". El estado de un pago lo cambia el proveedor
# desde /provider/payments, así que este archivo recorre el circuito completo --
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

  # Un mes ya pagado y cerrado: es el historial anterior que no se debe tocar.
  def previous_payment(consumer:, provider:, month:, discounted_price:)
    confirmed_order(
      consumer:, provider:, month:, quantity: 1, discounted_price:
    )
    account = consumer.accounts.find_by!(provider:)
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
  let(:previous_month) { Date.current.beginning_of_month.months_ago(1) }
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

    expect(page).to have_content(I18n.t("flash.payment_receipt_submitted"))
    within(find("[role=tabpanel]")) do
      expect(page).to have_content("Enviado")
    end
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
    visit provider_payments_path

    # Consistencia entre vistas: el importe que el proveedor aprueba es el mismo
    # que el empleado tiene en su cuenta, no dos cálculos distintos.
    expect(page).to have_content(users(:one).name)
    expect(page).to have_content("$300")

    click_on "Aprobar"
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
    visit provider_payments_path

    click_on "Rechazar"
    within(find("[role=dialog]")) { click_on "Rechazar comprobante" }
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
