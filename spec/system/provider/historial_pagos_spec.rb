# frozen_string_literal: true

require "rails_helper"

# Historia IBP-061: "Como PROVEEDOR, quiero consultar el historial de pagos y sus
# estados para disponer de trazabilidad."
#
# TODO(integración): falta implementar una forma de que la empresa (GoGrow) pague
# su cuenta desde la app antes de poder testear de punta a punta el criterio 1
# para los "pagos de GoGrow": hoy solo el empleado sube comprobantes, así que acá
# el pago de la empresa se carga a mano y solo se prueba cómo lo ve el proveedor.
# Historia: IBP-061 "historial de pagos del proveedor".
#
# TODO(integración): falta implementar el filtro por período y por estado antes
# de poder testear el criterio 2 completo ("filtrar por período, estado y
# pagador"). Hoy solo existe el filtro por cliente (la empresa) y la división
# Pendientes/Historial. Historia: IBP-061 "historial de pagos del proveedor".
RSpec.describe "Historial de pagos del proveedor" do
  fixtures :users, :companies, :providers, :consumers

  let(:provider) { providers(:tuviandita) }
  let(:provider_user) { users(:provider_user) }
  let(:employee) { users(:one) }
  let(:previous_month) { Date.current.beginning_of_month.months_ago(1) }

  before do
    Account.where(provider:).destroy_all
    consumers(:one).orders.destroy_all
  end

  def receipt_file
    Rails.root.join("public/icon.png").to_s
  end

  # La cuenta del empleado y la de la empresa las crea y las sincroniza
  # Order#ensure_accounts!, así que se viaja al mes para que caigan en él.
  # Precio 1000 con 300 a cargo del empleado: la empresa cubre 700.
  def confirmed_order(month:)
    travel_to(Time.zone.local(month.year, month.month, 5, 12)) do
      menu = Menu.create!(provider:, name: "Milanesa al pan", description: "Con papas", price: 1000)
      schedule = Schedule.create!(menu:, date: month + 7, amount: 20)

      Order.create!(
        consumer: consumers(:one), schedule:, amount: 1, price: 1000, discounted_price: 300,
        delivery_method: :office, status: :confirmed
      )
    end
  end

  def employee_account(month)
    consumers(:one).accounts.find_by!(provider:, month:)
  end

  def company_account(month)
    companies(:gogrow).accounts.find_by!(provider:, month:)
  end

  def payment_on(account, status:, at:, filename: nil, rejection_reason: nil)
    payment = account.payments.build(provider:, status:, rejection_reason:, created_at: at)
    if filename
      payment.receipt.attach(io: File.open(receipt_file), filename:, content_type: "image/png")
    end
    payment.save!
    payment
  end

  def month_name(month)
    I18n.l(month, format: :month_name_year)
  end

  def open_history
    visit provider_collections_path
    find("[role=tab]", text: "Historial").click
  end

  def history_card(client_name)
    find("[role=tabpanel] [data-slot=card]", text: client_name)
  end

  # Un mes cobrado: el empleado pagó al segundo intento y la empresa pagó su parte.
  def settled_previous_month
    confirmed_order(month: previous_month)
    rejected = payment_on(
      employee_account(previous_month), status: :rejected, rejection_reason: "No se lee el importe",
      at: previous_month + 19.days, filename: "primer-intento.png"
    )
    approved = payment_on(
      employee_account(previous_month), status: :approved,
      at: previous_month + 24.days, filename: "segundo-intento.png"
    )
    company = payment_on(
      company_account(previous_month), status: :approved,
      at: previous_month + 25.days, filename: "transferencia-gogrow.png"
    )
    [ rejected, approved, company ]
  end

  def review_employee_payment(decision)
    visit provider_collections_path
    click_on "Empleados"
    click_on employee.name
    click_on "Revisar pago"

    if decision == :approve
      within(find("[role=dialog]")) { click_on "Aprobar" }
      expect(page).to have_content(I18n.t("pages.provider_collections.review.approved_title"))
    else
      within(find("[role=dialog]")) { click_on "Rechazar" }
      within(find("[role=dialog]", text: "Rechazar comprobante")) do
        choose "Otro"
        fill_in "Motivo", with: "El importe no coincide"
        click_on "Rechazar comprobante"
      end
      expect(page).to have_content(I18n.t("pages.provider_collections.review.rejected_title"))
    end

    click_on I18n.t("pages.provider_collections.review.done")
  end

  def employee_uploads_receipt
    visit accounts_path
    # El empleado puede deberle a otros proveedores: se sube en la tarjeta de este.
    within(find("[role=tabpanel] [data-slot=card]", text: /\A#{provider_user.name}/)) do
      click_on "Subir comprobante de pago"
    end
    within(find("[role=dialog]")) do
      attach_file("Seleccionar archivo", receipt_file)
      click_on "Subir comprobante de pago"
    end
    expect(page).to have_content(I18n.t("pages.accounts.show.receipt_success_description"))
  end

  # Criterio 1 y 3 -- en el historial cada pago del empleado y de la empresa se ve
  # con su fecha, importe, origen y estado, y da acceso a su comprobante.
  it "shows each settled payment of the employees and the company with its date, amount, origin, status and receipt" do
    rejected, approved, company = settled_previous_month
    sign_in provider_user, role: :provider

    open_history

    within(history_card("GoGrow")) do
      expect(page).to have_content(month_name(previous_month))

      click_on "Empleados"
      click_on employee.name
      expect(page).to have_content(approved.created_at.strftime("%d/%m/%y"))
      expect(page).to have_content("300,00")

      expect(page).to have_button("Descargar comprobantes", exact: true)
      expect(page).to have_link("Descargar primer-intento.png", href: receipt_provider_payment_path(rejected))
      expect(page).to have_link("Descargar segundo-intento.png", href: receipt_provider_payment_path(approved))
      expect(page).to have_content(rejected.created_at.strftime("%d/%m/%y"))
      expect(page).to have_content("Rechazado")
      expect(page).to have_content("Confirmado")

      click_on "Empresa"
      expect(page).to have_content(company.created_at.strftime("%d/%m/%y"))
      expect(page).to have_content("700,00")
      expect(page).to have_link("Descargar comprobante", exact: true, href: receipt_provider_payment_path(company))
    end
  end

  # Criterio 3 -- tanto empleados como empresa consultan el consumo del cobro
  # confirmado desde Historial, sin abandonar el listado.
  it "opens the consumption detail for employees and the company from history" do
    settled_previous_month
    sign_in provider_user, role: :provider

    open_history
    within(history_card("GoGrow")) do
      click_on "Empleados"
      click_on employee.name
      click_on "Ver detalle"
    end

    within(find("[role=dialog]")) do
      expect(page).to have_content("Historial de consumo: #{month_name(previous_month)}")
      expect(page).to have_content("Milanesa al pan")
      expect(page).to have_content("Total: 300,00")
      click_on "Cerrar"
    end

    within(history_card("GoGrow")) do
      click_on "Empresa"
      click_on "Ver detalle"
    end

    within(find("[role=dialog]")) do
      expect(page).to have_content("Subtotal sin IVA")
      expect(page).to have_content("700,00")
      click_on "Viandas"
      expect(page).to have_content("Milanesa al pan")
    end
  end

  # Criterio 2 -- el único filtro que existe hoy es por pagador (el cliente).
  it "filters the history by client" do
    settled_previous_month
    acme = Company.create!(name: "Acme", address: "Rivera 1234")
    acme_account = Account.create!(owner: acme, provider:, month: previous_month, amount: 450)
    payment_on(acme_account, status: :approved, at: previous_month + 20.days)
    sign_in provider_user, role: :provider

    open_history
    expect(page).to have_css("[role=tabpanel] [data-slot=card]", text: "GoGrow")
    expect(page).to have_css("[role=tabpanel] [data-slot=card]", text: "Acme")

    click_on "Filtrar por cliente"
    find("[role=menuitemradio]", text: "Acme").click

    expect(page).to have_css("[role=tabpanel] [data-slot=card]", text: "Acme")
    expect(page).to have_no_css("[role=tabpanel] [data-slot=card]", text: "GoGrow")
    expect(page).to have_no_css("[role=menu]")

    click_on "Filtrar por cliente"
    find("[role=menuitemradio]", text: "Todos").click

    expect(page).to have_css("[role=tabpanel] [data-slot=card]", text: "GoGrow")
  end

  # Criterio 4 -- circuito real: el empleado sube, el proveedor rechaza, el
  # empleado vuelve a subir y el proveedor aprueba. El intento rechazado sigue en
  # el historial con su motivo, y el empleado ve el mismo estado e importe.
  it "keeps the rejected attempt in the history after the employee resubmits and the provider approves" do
    confirmed_order(month: previous_month)
    payment_on(company_account(previous_month), status: :approved, at: 1.minute.ago)

    sign_in employee
    employee_uploads_receipt
    sign_out

    sign_in provider_user, role: :provider
    review_employee_payment(:reject)
    sign_out

    sign_in employee
    employee_uploads_receipt
    sign_out

    sign_in provider_user, role: :provider
    review_employee_payment(:approve)

    payments = employee_account(previous_month).payments.order(:created_at)
    expect(payments.map(&:status)).to eq(%w[rejected approved])
    expect(payments.first.rejection_reason).to eq("El importe no coincide")

    open_history
    within(history_card("GoGrow")) do
      click_on "Empleados"
      click_on employee.name
      click_on "Ver comprobantes"
      payments.each do |payment|
        expect(page).to have_link(href: receipt_provider_payment_path(payment))
      end
      expect(page).to have_content("Rechazado")
      expect(page).to have_content("Confirmado")
    end

    # Persistencia: el historial sigue igual tras recargar.
    page.refresh
    find("[role=tab]", text: "Historial").click
    expect(page).to have_css("[role=tabpanel] [data-slot=card]", text: "GoGrow")

    # Consistencia entre vistas: el empleado ve la cuenta aceptada por el mismo importe.
    sign_out
    sign_in employee
    visit accounts_path
    find("[role=tab]", text: "Historial").click
    within(find("[role=tabpanel]")) do
      expect(page).to have_content("Aceptado")
      expect(page).to have_content("$300")
    end
  end

  # Transversal -- permisos: otro rol no llega a la pantalla de cobros.
  it "does not let an employee reach the collections screen" do
    settled_previous_month
    sign_in employee

    visit provider_collections_path

    expect(page).to have_no_current_path(provider_collections_path)
    expect(page).to have_no_content("transferencia-gogrow.png")
  end

  # Transversal -- privacidad entre pares: otro proveedor no ve estos cobros ni
  # llega a sus comprobantes o al detalle por id.
  it "does not show these payments to another provider" do
    rejected, approved, company = settled_previous_month
    sign_in users(:other_provider_user), role: :provider

    open_history
    expect(page).to have_no_css("[role=tabpanel] [data-slot=card]", text: "GoGrow")

    [ rejected, approved, company ].each do |payment|
      expect(status_of(receipt_provider_payment_path(payment))).to eq(404)
    end
    expect(status_of(provider_collection_path(employee_account(previous_month)))).to eq(404)
  end

  def status_of(path)
    page.evaluate_async_script(<<~JS, path)
      const done = arguments[arguments.length - 1]
      fetch(arguments[0])
        .then((response) => done(response.status))
        .catch(() => done(0))
    JS
  end
end
