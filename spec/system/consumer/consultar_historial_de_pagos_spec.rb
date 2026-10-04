# frozen_string_literal: true

require "rails_helper"

# Historia IBP-020: "Como EMPLEADO, quiero consultar mi historial de pagos y sus
# estados para mantener un registro de mis gastos."
#
# La pantalla es /accounts, a donde el sidebar del empleado manda con "Pagos".
# La pestaña "Pendientes" lista las cuentas con deuda que todavía no tienen un
# pago aprobado y la pestaña "Historial" las que ya lo tienen: el historial es a
# nivel de cuenta (mes + proveedor), no de pago suelto, así que una cuenta
# aparece una sola vez aunque haya tenido varios intentos de pago.
#
# Criterio 1 incompleto: la tarjeta del historial muestra fecha, importe y
# estado, pero no el proveedor -- ni la tarjeta lo renderiza ni AccountSerializer
# se lo manda (solo expone provider_id). No es trabajo pendiente: la pantalla ya
# está publicada y el empleado la usa, le falta un dato que el criterio exige.
# Ver docs/reports/defects/DEFECT-historial-sin-proveedor-27-09-2026.md. Por eso
# el ejemplo del criterio 1 no afirma el proveedor.
#
# Criterio 2 parcial: "Ver detalle" abre los pedidos que componen la deuda y el
# total, pero el comprobante no está dentro de ese panel: se llega con el botón
# "Descargar comprobante de pago" de la misma tarjeta. El ejemplo del criterio 2
# cubre las dos mitades por separado.
RSpec.describe "Consultar el historial de pagos visto por el empleado" do
  fixtures :users, :consumers, :companies, :providers

  # El comprobante que se sube y se descarga es un PNG real: el modelo valida el
  # content_type del adjunto, así que no sirve un StringIO con texto cualquiera.
  def receipt_file
    Rails.root.join("public/icon.png")
  end

  # La cuenta la crea y la sincroniza Order#assign_account con la deuda real, así
  # que se viaja al mes que se quiere: es la única forma de que la cuenta caiga en
  # ese mes sin asignar cuentas a mano (el modelo lo descarta a propósito).
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

  # Un pago con comprobante es lo que mete la cuenta en el historial: Account.history
  # son las cuentas con algun pago aprobado.
  def payment_for(account, status:, filename:, rejection_reason: nil)
    payment = account.payments.build(
      provider: account.provider, status:, rejection_reason:
    )
    payment.receipt.attach(
      io: StringIO.new(File.binread(receipt_file)),
      filename:, content_type: "image/png"
    )
    payment.save!
    payment
  end

  # Devuelve la cuenta ya pagada del mes indicado, con su pago aprobado.
  def paid_month(consumer:, provider:, month:, quantity:, discounted_price:)
    confirmed_order(
      consumer:, provider:, month:, quantity:, discounted_price:
    )
    account = consumer.accounts.find_by!(provider:, month: month.beginning_of_month)
    [ account, payment_for(account, status: :approved, filename: "comprobante.png") ]
  end

  # La pestaña se elige en el browser (los Tabs no están controlados), así que el
  # server siempre monta "Pendientes" como la activa: después de un reload hay que
  # volver a clickear "Historial".
  def open_history_tab
    find("[role=tab]", text: "Historial").click
  end

  def open_history
    visit accounts_path
    open_history_tab
  end

  # El driver de Selenium no expone el status de la última respuesta, así que se
  # pregunta con un fetch desde la misma sesión del browser: es la petición que
  # haría el <a> de "Descargar comprobante de pago", con sus cookies.
  def receipt_status_for(payment)
    page.evaluate_async_script(<<~JS, receipt_payment_path(payment))
      const done = arguments[arguments.length - 1]
      fetch(arguments[0])
        .then((response) => done(response.status))
        .catch(() => done(0))
    JS
  end

  let(:employee) { users(:one) }
  let(:provider) { providers(:tuviandita) }
  let(:previous_month) { Date.current.change(day: 15).months_ago(1) }
  let(:previous_month_label) { I18n.l(previous_month, format: :month_year) }

  # Criterio 1
  it "shows the employee's own payments with their date, amount and status" do
    _account, = paid_month(
      consumer: consumers(:one), provider:, month: previous_month,
      quantity: 2, discounted_price: 300
    )
    sign_in employee

    open_history

    within(find("[role=tabpanel]")) do
      expect(page).to have_content(previous_month_label)
      expect(page).to have_content("$300")
      expect(page).to have_content("2 viandas")
      expect(page).to have_content("Aceptado")
    end
  end

  # Criterio 1 -- el caso de partida: sin pagos el historial lo dice, en vez de
  # mostrar una lista vacía sin explicación.
  it "tells the employee when there are no payments yet" do
    sign_in employee

    open_history

    within(find("[role=tabpanel]")) do
      expect(page).to have_content("Todavía no hiciste ningún pago.")
      expect(page).to have_no_link("Descargar comprobante de pago")
    end
  end

  # Criterio 2
  it "opens a payment to see the debt it settles and reaches its receipt" do
    _account, payment = paid_month(
      consumer: consumers(:one), provider:, month: previous_month,
      quantity: 2, discounted_price: 300
    )
    sign_in employee

    open_history
    within(find("[role=tabpanel]")) { click_on "Ver detalle" }

    within(find("[role=dialog]")) do
      expect(page).to have_content("Consumo #{previous_month_label}")
      expect(page).to have_content("Milanesa al pan")
      expect(page).to have_content("300")
      expect(page).to have_content("Total")
      click_on "Cerrar"
    end

    # El comprobante se baja del endpoint del propio empleado, no del del proveedor.
    expect(page).to have_link(
      "Descargar comprobante de pago", href: receipt_payment_path(payment)
    )
  end

  # Criterio 4
  it "keeps another employee's payments out of the history" do
    _own_account, = paid_month(
      consumer: consumers(:one), provider:, month: previous_month,
      quantity: 2, discounted_price: 300
    )
    _other_account, other_payment = paid_month(
      consumer: consumers(:other), provider:, month: previous_month,
      quantity: 5, discounted_price: 5000
    )
    sign_in employee

    open_history

    within(find("[role=tabpanel]")) do
      expect(page).to have_content("$300")
      expect(page).to have_content("2 viandas")
      expect(page).to have_no_content("$5000")
      expect(page).to have_no_link(
        "Descargar comprobante de pago", href: receipt_payment_path(other_payment)
      )
    end
  end

  # Criterio 4 -- el aislamiento de arriba es de la lista; esto es del acceso
  # directo por id: el empleado que adivine la URL del comprobante de otro tiene
  # que rebotar en un 404, no en un comprobante ajeno. Y el suyo sí se sirve, que
  # es lo que hace que el 404 sea una guarda y no una pantalla rota.
  it "does not serve another employee's receipt by its direct url" do
    _own_account, own_payment = paid_month(
      consumer: consumers(:one), provider:, month: previous_month,
      quantity: 2, discounted_price: 300
    )
    _other_account, other_payment = paid_month(
      consumer: consumers(:other), provider:, month: previous_month,
      quantity: 5, discounted_price: 5000
    )
    sign_in employee
    visit accounts_path

    expect(receipt_status_for(other_payment)).to eq(404)
    expect(receipt_status_for(own_payment)).to eq(200)
  end

  # Transversal -- permisos: la pantalla es del empleado y no se alcanza con otro
  # rol ni sin sesión, y el rebote no deja ver ningún pago en el HTML.
  it "does not let a provider reach the payments screen" do
    _account, = paid_month(
      consumer: consumers(:one), provider:, month: previous_month,
      quantity: 2, discounted_price: 300
    )
    sign_in users(:provider_user), role: :provider

    visit accounts_path

    expect(page).to have_no_current_path(accounts_path)
    expect(page).to have_no_content("$300")
    expect(page).to have_no_link("Descargar comprobante de pago")
  end

  it "sends a visitor without a session to sign in" do
    _account, = paid_month(
      consumer: consumers(:one), provider:, month: previous_month,
      quantity: 2, discounted_price: 300
    )

    visit accounts_path

    expect(page).to have_current_path(sign_in_path)
    expect(page).to have_no_content("$300")
  end

  # Transversal -- persistencia: el historial sobrevive un reload y un ida y vuelta
  # de sesión, y sigue siendo el mismo pago.
  it "keeps the history across a reload and signing out and in again" do
    _account, payment = paid_month(
      consumer: consumers(:one), provider:, month: previous_month,
      quantity: 2, discounted_price: 300
    )
    sign_in employee

    open_history
    expect(page).to have_content("$300")

    refresh
    open_history_tab
    expect(page).to have_content("$300")

    sign_out
    sign_in employee
    open_history

    within(find("[role=tabpanel]")) do
      expect(page).to have_content(previous_month_label)
      expect(page).to have_link(
        "Descargar comprobante de pago", href: receipt_payment_path(payment)
      )
    end
  end
end
