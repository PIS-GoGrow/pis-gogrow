# frozen_string_literal: true

require "rails_helper"

# Historia IBP-108: "Como EMPLEADO quiero poder completar el flujo de pagos
# desde la aplicación MOBILE."
#
# Criterio 1: el empleado ve sus pagos pendientes, con la deuda total y la que
# debe a cada proveedor. Criterio 2: ve su historial de pagos.
#
# El flujo arranca en el inicio del empleado a 375 px de ancho y entra a Pagos
# por el ítem del menú inferior: en mobile el sidebar se oculta, así que esa es
# la única navegación real a la pantalla. Los mismos criterios en desktop ya
# están cubiertos por consultar_historial_de_pagos_spec.rb, payments_spec.rb y
# estado_pago_actualiza_historial_spec.rb; acá se prueba el recorrido mobile,
# no se repiten esos casos.
RSpec.describe "Flujo de pagos del empleado en mobile", type: :system do
  fixtures :users, :consumers, :companies, :providers, :accounts

  let(:employee) { users(:one) }
  let(:tuviandita) { providers(:tuviandita) }
  let(:endulzate) { providers(:endulzate) }
  let(:office_provider) { providers(:office_provider) }
  let(:previous_month) { Date.current.change(day: 15).months_ago(1) }
  let(:previous_month_label) { I18n.l(previous_month, format: :month_year) }

  before do
    page.current_window.resize_to(375, 667)
    sign_in employee, role: :consumer
  end

  after { page.current_window.resize_to(1400, 1400) }

  # El menú inferior es lo único que navega en mobile: el sidebar está oculto.
  def open_payments_from_mobile_nav
    visit_hydrated dashboard_path
    within("nav.fixed") { click_link "Pagos" }
    expect(page).to have_current_path(accounts_path)
  end

  # La tarjeta del proveedor es la que tiene su nombre como título; las de
  # período (AccountCard) cuelgan de ella.
  def provider_card(provider)
    find("[data-slot=card-title]", text: provider.user.name, exact_text: true)
      .ancestor("[data-slot=card]")
  end

  def open_history_tab
    find("[role=tab]", text: "Historial").click
  end

  # La cuenta la crea y la sincroniza Order#ensure_accounts! con la deuda real,
  # así que se viaja al mes para que caiga en ese período.
  def paid_month(month:)
    travel_to(Time.zone.local(month.year, month.month, month.day, 12)) do
      menu = Menu.create!(
        provider: tuviandita, name: "Milanesa al pan", description: "Con papas", price: 1000
      )
      schedule = Schedule.create!(menu:, date: month + 7, amount: 20)

      Order.create!(
        consumer: consumers(:one), schedule:,
        amount: 2, price: 2000, discounted_price: 300,
        delivery_method: :office, status: :confirmed
      )
    end

    account = consumers(:one).accounts.find_by!(
      provider: tuviandita, month: month.beginning_of_month
    )
    payment = account.payments.build(provider: tuviandita, status: :approved)
    payment.receipt.attach(
      io: StringIO.new(File.binread(Rails.root.join("public/icon.png"))),
      filename: "comprobante.png", content_type: "image/png"
    )
    payment.save!

    payment
  end

  # Criterio 1
  it "muestra la deuda total y la de cada proveedor al entrar desde el menú mobile" do
    open_payments_from_mobile_nav

    within(find("[role=tabpanel]")) do
      # Deuda total: $450,75 de TuViandita + $500 de Endulzate.
      expect(page).to have_content(I18n.t("pages.accounts.index.pending_payments"))
      expect(page).to have_content(I18n.t("pages.accounts.index.total_debt"))
      expect(page).to have_content("$950,75")

      # Cada proveedor muestra solo su propia deuda...
      within(provider_card(tuviandita)) do
        expect(page).to have_content("$450,75")
        expect(page).to have_no_content("$500")
      end

      within(provider_card(endulzate)) do
        expect(page).to have_content("$500")
        expect(page).to have_no_content("$450,75")
      end

      # ...y el que no le debe nada lo dice, en vez de quedar afuera de la lista.
      within(provider_card(office_provider)) do
        expect(page).to have_content(I18n.t("pages.accounts.index.no_debt"))
      end
    end
  end

  # Criterio 1 -- el caso de partida: sin deuda la pantalla no rompe y el total
  # es cero.
  it "muestra deuda cero cuando el empleado no debe nada" do
    consumers(:one).accounts.destroy_all

    open_payments_from_mobile_nav

    within(find("[role=tabpanel]")) do
      expect(page).to have_content("$0")
      expect(page).to have_content(I18n.t("pages.accounts.index.pending_meals", count: 0))
      expect(page).to have_content(I18n.t("pages.accounts.index.no_debt"), count: 3)
    end
  end

  # Criterio 2
  it "muestra el historial de pagos con fecha de vencimiento, proveedor, mes, importe y estado" do
    payment = paid_month(month: previous_month)

    open_payments_from_mobile_nav
    open_history_tab

    within(find("[role=tabpanel]")) do
      expect(page).to have_content(DateFormat.short(payment.account.due_date))
      expect(page).to have_content("#{tuviandita.user.name}: #{previous_month_label}")
      expect(page).to have_content("$300")
      expect(page).to have_content("2 viandas")
      expect(page).to have_content(I18n.t("pages.accounts.show.status_accepted"))
      expect(page).to have_link(I18n.t("pages.accounts.show.download_receipt"))
    end
  end

  # Criterio 2 -- el caso de partida: sin pagos el historial lo dice.
  it "avisa cuando el empleado todavía no hizo ningún pago" do
    open_payments_from_mobile_nav
    open_history_tab

    within(find("[role=tabpanel]")) do
      expect(page).to have_content(I18n.t("pages.accounts.index.history_empty"))
      expect(page).to have_no_link(I18n.t("pages.accounts.show.download_receipt"))
    end
  end

  # Transversal -- permisos y privacidad: dos empleados del mismo rol no ven la
  # deuda del otro, ni siquiera entrando por el menú mobile.
  it "no muestra la deuda de otro empleado" do
    other_account = accounts(:other_tuviandita_current)

    open_payments_from_mobile_nav

    within(find("[role=tabpanel]")) do
      expect(page).to have_content("$950,75")
      expect(page).to have_no_content(Account.format_amount(other_account.amount))
    end
  end

  # Transversal -- permisos: la pantalla es del empleado; un proveedor rebota y
  # no ve el menú de pagos en mobile.
  it "no deja entrar a Pagos a un proveedor" do
    sign_out
    sign_in users(:provider_user), role: :provider

    visit_hydrated dashboard_path

    expect(page).to have_no_link("Pagos")
    visit accounts_path

    expect(page).to have_no_current_path(accounts_path)
    expect(page).to have_content(I18n.t("flash.no_permission"))
  end

  # Transversal -- persistencia: la deuda y el historial sobreviven un reload y
  # un ida y vuelta de sesión.
  it "mantiene la deuda y el historial después de recargar y volver a entrar" do
    payment = paid_month(month: previous_month)

    open_payments_from_mobile_nav
    expect(page).to have_content("$950,75")

    refresh
    within(find("[role=tabpanel]")) { expect(page).to have_content("$950,75") }

    sign_out
    sign_in employee, role: :consumer
    open_payments_from_mobile_nav
    within(find("[role=tabpanel]")) { expect(page).to have_content("$950,75") }

    open_history_tab
    within(find("[role=tabpanel]")) do
      expect(page).to have_content("#{tuviandita.user.name}: #{previous_month_label}")
      expect(page).to have_content("$300")
      expect(page).to have_link(
        I18n.t("pages.accounts.show.download_receipt"),
        href: receipt_payment_path(payment)
      )
    end
  end
end
