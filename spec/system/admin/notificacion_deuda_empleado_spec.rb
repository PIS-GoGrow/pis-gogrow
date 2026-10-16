# frozen_string_literal: true

# Historia IBP-046: "Como RR.HH., quiero recibir una notificación cuando un
# empleado deba más de un mes (calendario) a algún proveedor para poder
# notificarlo del tema."
#
# Criterios: (1) cuando una deuda supera un mes de antigüedad, RR.HH. recibe una
# alerta; (2) la alerta identifica al empleado, al proveedor, el período de
# origen, el monto y su antigüedad; (3) respeta las preferencias de canal y
# frecuencia; (4) una deuda resuelta deja de generar recordatorios y la alerta
# se marca como resuelta.
#
# El aviso lo arma el job diario (EmployeeDebtAlertsJob) y aparece en el inicio
# de RR.HH., que es donde vive el banner de notificaciones.
#
# TODO(integración): falta implementar una preferencia de frecuencia (hoy la
# única frecuencia es el job diario más un aviso nuevo como máximo una vez por
# mes, en EmployeeDebtNotifications#new_notice_due?). Las preferencias de canal
# (WhatsApp) llegan hasta la suscripción en settings/notifications, que ya cubren
# spec/requests/settings/notifications_spec.rb y
# spec/system/consumer/notificaciones_whatsapp_spec.rb; el envío en sí sigue
# pendiente en WhatsappSenderJob. Recién ahí se podrá testear el criterio 3 de
# punta a punta.

require "rails_helper"

RSpec.describe "Notificación de deudas de empleados a proveedores", type: :system do
  fixtures :users, :companies, :admins, :providers, :consumers

  let(:company) { companies(:gogrow) }
  let(:admin_user) { users(:admin) }
  let(:provider) { providers(:endulzate) }
  let(:title) { I18n.t("notifications.employee_debt_overdue.title") }

  # La deuda del mes M recién cuenta como "de más de un mes" cuando vence el
  # pago del mes siguiente al de su vencimiento: avisa desde el día 10 de M+2.
  let(:month) { Date.current.beginning_of_month - 2.months }
  let(:due_date) { Account.new(month:).due_date }
  let(:not_yet) { due_date.next_month }
  let(:overdue) { due_date.next_month + 1.day }

  let!(:company_account) { Account.create!(owner: company, provider:, month:, amount: 300) }
  let!(:debt_account) { Account.create!(owner: consumers(:one), provider:, month:, amount: 200) }

  before do
    Notification::Configuration.find_or_create_by!(key: "employee_debts") do |configuration|
      configuration.roles = %w[admin]
    end
  end

  def run_reminders(on:)
    EmployeeDebtAlertsJob.perform_now(date: on)
  end

  def open_admin_home(user = admin_user)
    sign_in user, role: :admin
    visit admin_dashboard_path
  end

  def period
    I18n.l(month, format: :month_name_year).downcase
  end

  def add_payment(status:, to:)
    payment = to.payments.build(provider: to.provider, status:)
    payment.receipt.attach(io: File.open(Rails.root.join("public/icon.png")), filename: "comprobante.png")
    payment.save!
    payment
  end

  it "avisa a RR.HH. cuando la deuda supera el mes de antigüedad" do
    run_reminders(on: overdue)

    open_admin_home

    expect(page).to have_content(title)
    # El criterio 2 pide además la antigüedad de la deuda, que el aviso todavía
    # no muestra (EmployeeDebtNotifications#description_data sólo arma empleado,
    # proveedor, período y monto).
    expect(page).to have_content(
      "Test User tiene pendiente su pago a Other Provider User correspondiente a #{period}. " \
      "La deuda asciende a $200. Podés enviarle un recordatorio."
    )
  end

  it "todavía no avisa cuando no pasó el mes de antigüedad" do
    run_reminders(on: not_yet)

    open_admin_home

    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(title)
  end

  it "resume la cantidad de empleados y la deuda total cuando son varios" do
    Account.create!(owner: consumers(:other), provider:, month:, amount: 100)
    run_reminders(on: overdue)

    open_admin_home

    expect(page).to have_content(
      "2 empleados tienen pendiente su pago a Other Provider User correspondiente a #{period}. " \
      "La deuda total asciende a $300. Podés enviarles un recordatorio."
    )
  end

  it "RR.HH. descarta el aviso, que queda resuelto y no vuelve a aparecer" do
    run_reminders(on: overdue)

    open_admin_home
    expect(page).to have_content(title)

    click_button "Cerrar notificación"
    expect(page).to have_no_content(title)

    refresh
    expect(page).to have_no_content(title)
  end

  it "deja de avisar y resuelve el aviso cuando se resuelve la deuda" do
    run_reminders(on: overdue)
    open_admin_home
    expect(page).to have_content(title)

    add_payment(status: :approved, to: debt_account)
    run_reminders(on: overdue)

    refresh
    expect(page).to have_no_content(title)
  end

  it "mantiene el aviso tras recargar y volver a iniciar sesión" do
    run_reminders(on: overdue)

    open_admin_home
    expect(page).to have_content(title)

    refresh
    expect(page).to have_content(title)

    sign_out
    open_admin_home
    expect(page).to have_content(title)
  end

  it "se lo muestra a todos los admins de la empresa" do
    second_admin = User.create!(email: "second-admin@example.com", name: "Otra RRHH GoGrow", password: "password123456")
    Admin.create!(user: second_admin, company:)
    run_reminders(on: overdue)

    open_admin_home(second_admin)

    expect(page).to have_content(title)
    expect(page).to have_content(
      "Test User tiene pendiente su pago a Other Provider User correspondiente a #{period}. " \
      "La deuda asciende a $200. Podés enviarle un recordatorio."
    )
  end

  describe "permisos" do
    it "no le muestra el aviso a RR.HH. de otra empresa" do
      acme = Company.create!(name: "Acme", address: "Rivera 1234")
      acme_admin = User.create!(email: "acme-admin@example.com", name: "Acme RRHH", password: "password123456")
      Admin.create!(user: acme_admin, company: acme)
      run_reminders(on: overdue)

      open_admin_home(acme_admin)

      expect(page).to have_content("Hola,")
      expect(page).to have_no_content(title)
    end

    it "no le muestra el aviso al empleado ni al proveedor en su propio inicio" do
      run_reminders(on: overdue)

      sign_in users(:one), role: :consumer
      visit dashboard_path
      expect(page).to have_content("Hola,")
      expect(page).to have_no_content(title)
      sign_out

      sign_in users(:provider_user), role: :provider
      visit provider_dashboard_path
      expect(page).to have_no_content(title)
    end
  end
end
