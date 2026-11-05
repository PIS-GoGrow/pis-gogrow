# frozen_string_literal: true

require "rails_helper"

# Historia: "Como PROVEEDOR, quiero poder gestionar mis pagos desde la aplicación
# MOBILE." Sin criterios escritos: C1–C6 salen del PR #218 (feat/mobile-provider-pagos).
#
# TODO(integración): falta implementar el "| N viandas" junto al subtotal del
# modal "Ver detalle" de Empresa (está en Figma) antes de poder testear el
# desglose de IVA en mobile; además ese desglose solo aparece con
# COMPANY_ACCOUNT_VAT_ENABLED=true. Historia: "proveedor gestiona sus pagos en mobile".
RSpec.describe "Gestión de pagos del proveedor en mobile", type: :system do
  fixtures :users, :companies, :providers, :consumers

  let(:provider) { providers(:tuviandita) }
  let(:provider_user) { users(:provider_user) }
  let(:employee) { users(:one) }
  let(:previous_month) { Date.current.beginning_of_month.months_ago(1) }
  let(:review) { "pages.provider_collections.review" }

  # El 15 la cuenta del mes anterior ya venció (vence el 10) y el recordatorio aplica.
  let!(:today) { Date.current.change(day: 15).noon }

  before do
    travel_to today
    Account.where(provider:).destroy_all
    consumers(:one).orders.destroy_all
    Notification::Configuration.find_or_create_by!(key: "provider_payment_reminders") { |c| c.roles = [ "consumer" ] }
    page.current_window.resize_to(375, 812)
  end

  after { travel_back }

  def receipt_file = Rails.root.join("public/icon.png").to_s

  # Order#ensure_accounts! crea la cuenta del mes en que se crea el pedido.
  def confirmed_order(month:, dish: "Milanesa al pan")
    travel_to Time.zone.local(month.year, month.month, 5, 12)
    menu = Menu.create!(provider:, name: dish, description: "Con papas", price: 1000)
    schedule = Schedule.create!(menu:, date: Date.current, amount: 20)
    Order.create!(
      consumer: consumers(:one), schedule:, amount: 1, price: 1000, discounted_price: 300,
      delivery_method: :office, status: :confirmed
    )
  ensure
    travel_to today
  end

  def employee_account(month) = consumers(:one).accounts.find_by!(provider:, month:)

  def submitted_payment(month: previous_month)
    confirmed_order(month:)
    payment = employee_account(month).payments.build(provider:, status: :submitted)
    payment.receipt.attach(io: File.open(receipt_file), filename: "transferencia.png", content_type: "image/png")
    payment.save!
    payment
  end

  def open_employee_row
    sign_in provider_user, role: :provider
    visit_hydrated provider_collections_path
    click_on "Empleados"
    click_on employee.name
  end

  def report(reason, details: nil)
    click_on "Revisar pago"
    within(find("[role=dialog]")) { click_on "Reportar" }
    within(find("[role=dialog]", text: "Reportar un problema")) do
      find("[data-testid=provider-payment-report-reason-#{reason}]").click
      fill_in "Describir el motivo", with: details if details
      click_on "Continuar"
    end
  end

  def no_horizontal_overflow?
    page.evaluate_script(<<~JS)
      document.documentElement.scrollWidth <= document.documentElement.clientWidth &&
        [...document.querySelectorAll("[role=dialog] [data-slot=table-container]")]
          .every((el) => el.scrollWidth <= el.clientWidth)
    JS
  end

  # C1 + C2: estados y resumen del proveedor; Confirmar aprueba de verdad y el
  # empleado ve el mismo estado e importe en su historial.
  it "confirma un comprobante por revisar con los textos del proveedor" do
    payment = submitted_payment
    open_employee_row

    # Cuenta lo que todavía no está confirmado: el empleado por revisar y la
    # empresa, que no subió comprobante.
    expect(page).to have_content("2 cobros pendientes de confirmación")
    expect(page).to have_content("Por revisar")

    click_on "Revisar pago"
    within(find("[role=dialog]")) do
      expect(page).to have_content(I18n.t("#{review}.check_receipt"))
      expect(page).to have_link(I18n.t("#{review}.download"), href: receipt_provider_payment_path(payment))
      expect(page).to have_link(I18n.t("#{review}.open_receipt"))
      expect(page).not_to have_button("Aprobar")
      click_on "Confirmar"
    end
    expect(page).to have_content(I18n.t("#{review}.approved_title"))
    click_on I18n.t("#{review}.done")

    expect(payment.reload).to be_approved
    expect(page).to have_content("$300 en cobros confirmados")
    expect(page).to have_content("1 cobro pendiente de confirmación")

    # Historial solo lista meses cobrados por completo y la empresa sigue debiendo.
    visit_hydrated provider_collections_path
    click_on "Empleados"
    expect(page).to have_content("Confirmado")

    sign_out
    sign_in employee, role: :consumer
    visit_hydrated accounts_path
    find("[role=tab]", text: "Historial").click
    within(find("[role=tabpanel]")) do
      expect(page).to have_content(I18n.l(previous_month, format: :month_name_year))
      expect(page).to have_content("Confirmado")
      expect(page).to have_content("$300")
    end
  end

  # C2: el mes en curso no se puede confirmar, pero sí reportar.
  it "no deja confirmar un comprobante del mes en curso" do
    submitted_payment(month: Date.current.beginning_of_month)
    open_employee_row

    click_on "Revisar pago"
    within(find("[role=dialog]")) do
      expect(page).to have_button("Confirmar", disabled: true)
      expect(page).to have_content(/mes en curso/)
      expect(page).to have_button("Reportar", disabled: false)
    end
  end

  # C3: el reporte reemplaza al modal del comprobante y Volver lo reabre; sin
  # motivo no se puede continuar.
  it "reemplaza el modal del comprobante por el reporte y vuelve con Volver" do
    payment = submitted_payment
    open_employee_row

    click_on "Revisar pago"
    within(find("[role=dialog]")) { click_on "Reportar" }

    expect(page).to have_css("[role=dialog]", count: 1)
    within(find("[role=dialog]")) do
      expect(page).to have_content("Reportar un problema")
      expect(page).to have_button("Continuar", disabled: true)
      click_on "Volver"
    end

    expect(page).to have_css("[role=dialog]", count: 1)
    expect(page).to have_button("Confirmar")
    expect(payment.reload).to be_submitted
  end

  # C3: "Otro motivo" sin descripción guarda "Otro motivo" y el empleado lo ve.
  it "rechaza con 'Otro motivo' sin descripción" do
    payment = submitted_payment
    open_employee_row

    report("other")
    expect(page).to have_content(I18n.t("#{review}.rejected_title"))
    click_on I18n.t("#{review}.done")

    expect(payment.reload).to be_rejected
    expect(payment.rejection_reason).to eq("Otro motivo")
    expect(page).to have_content("1 cobro rechazado")

    sign_out
    sign_in employee, role: :consumer
    visit_hydrated accounts_path
    expect(page).to have_content("Otro motivo")
  end

  # C3, borde: la descripción admite 500 caracteres; el 501 no entra.
  it "corta la descripción de 'Otro motivo' en 500 caracteres" do
    payment = submitted_payment
    open_employee_row

    report("other", details: "a" * 501)
    expect(page).to have_content(I18n.t("#{review}.rejected_title"))

    expect(payment.reload.rejection_reason).to eq("a" * 500)
  end

  # C3 + C4 + C5: pago parcial, tarjeta del comprobante y recordatorio en espera
  # 3 días (deshabilitado, no oculto) que después se habilita.
  it "registra un pago parcial y deja el recordatorio en espera por 3 días" do
    payment = submitted_payment
    open_employee_row

    report("partial_payment")
    expect(page).to have_content(I18n.t("#{review}.partial_title"))
    click_on I18n.t("#{review}.done")

    expect(payment.reload).to be_partial
    expect(page).to have_content("Falta una parte del pago.")

    expect(page).to have_content(payment.created_at.strftime("%d/%m/%y"))
    expect(page).to have_content("Pago parcial")
    expect(page).to have_content("transferencia.png")
    expect(page).to have_content("4,07 KB")
    expect(page).to have_link("Descargar transferencia.png", href: receipt_provider_payment_path(payment))
    expect(page).not_to have_button("Descargar comprobantes")

    expect(page).to have_button(I18n.t("pages.provider_collections.reminder.trigger"), disabled: true)
    expect(page).to have_content("Próximo envío disponible el")

    travel 3.days
    visit_hydrated provider_collections_path
    click_on "Empleados"
    click_on employee.name

    expect(page).to have_button(I18n.t("pages.provider_collections.reminder.trigger"), disabled: false)
    expect(page).not_to have_content("Próximo envío disponible el")
  end

  # C6: a 375 px las tablas de los modales de detalle entran sin scroll horizontal.
  it "muestra los detalles de consumo sin scroll horizontal" do
    dish = "Milanesa napolitana con papas fritas y ensalada mixta"
    # "Ver detalle del consumo" es del mes en curso; "Ver detalle", de una cuenta vencida.
    confirmed_order(month: Date.current.beginning_of_month, dish:)
    confirmed_order(month: previous_month, dish:)
    sign_in provider_user, role: :provider
    visit_hydrated provider_collections_path

    click_on "Ver detalle del consumo"
    within(find("[role=dialog]")) do
      find("button", text: "Día: #{Date.current.change(day: 5).strftime("%d/%m")}").click
      expect(page).to have_content(employee.name)
    end
    expect(no_horizontal_overflow?).to be(true)
    within(find("[role=dialog]")) { click_on "Cerrar" }
    expect(page).not_to have_css("[role=dialog]")

    card = find("[data-slot=card]", text: I18n.l(previous_month, format: :month_name_year))
    within(card) do
      click_on "Empleados"
      click_on employee.name
      click_on "Ver detalle", exact: true
    end
    within(find("[role=dialog]")) { expect(page).to have_content("Milanesa napolitana") }
    expect(no_horizontal_overflow?).to be(true)
    within(find("[role=dialog]")) { click_on "Cerrar" }
    expect(page).not_to have_css("[role=dialog]")

    within(card) do
      click_on "Empresa"
      find_all(:button, "Ver detalle", exact: true).last.click
    end
    within(find("[role=dialog]")) do
      # El click puede llegar antes de que el diálogo termine de abrir; se reintenta.
      3.times do
        find("[role=tab]", text: "Viandas").click
        break if page.has_css?("[role=tab][data-state=active]", text: "Viandas", wait: 1)
      end
      expect(page).to have_content("Milanesa napolitana")
    end
    expect(no_horizontal_overflow?).to be(true)
  end
end
