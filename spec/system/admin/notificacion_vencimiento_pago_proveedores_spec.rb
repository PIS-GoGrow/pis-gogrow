# frozen_string_literal: true

# Historia IBP-045: "Como RR.HH., quiero recibir una notificación cuando se
# aproxime o se registre un pago de GoGrow a un proveedor, para no omitir la
# transferencia correspondiente."
#
# Criterios: (1) aviso 3 días antes del vencimiento; (2) aviso cuando el pago ya
# venció. El aviso lo arma el job diario y llega al inicio de RR.HH., que es
# donde vive el banner de notificaciones.

require "rails_helper"

RSpec.describe "Notificación de vencimiento de pagos a proveedores", type: :system do
  fixtures :users, :companies, :admins, :providers

  let(:company) { companies(:gogrow) }
  let(:admin_user) { users(:admin) }
  let(:provider) { providers(:endulzate) }
  let(:upcoming_title) { I18n.t("notifications.company_payment_upcoming.title") }
  let(:overdue_title) { I18n.t("notifications.company_payment_overdue.title") }

  # Período cerrado, con deuda y sin comprobante: lo que el job diario vigila.
  let(:account) do
    Account.create!(
      owner: company,
      provider:,
      month: Date.current.beginning_of_month - 2.months,
      amount: 4500
    )
  end
  # month + 1 mes + 4 días.
  let(:due_date) { account.due_date }

  before do
    Notification::Configuration.find_or_create_by!(key: "company_payments") do |configuration|
      configuration.roles = %w[admin]
    end
  end

  # El job diario arma los avisos: se le pasa la fecha para fijar el escenario
  # sin viajar en el tiempo (el reloj de Rails no es el del browser).
  def run_reminders(on:)
    CompanyPaymentRemindersJob.perform_now(date: on)
  end

  def open_admin_home(user = admin_user)
    sign_in user, role: :admin
    visit admin_dashboard_path
  end

  def period
    I18n.l(account.month, format: :month_name_year).downcase
  end

  def payment_description(verb)
    "El pago de GoGrow a #{provider.user.name} por #{period} " \
      "(#{account.formatted_amount}) #{verb} el #{I18n.l(due_date)}. Revisá el detalle en Pagos."
  end

  it "avisa a RR.HH. tres días antes del vencimiento y no deja descartar el aviso" do
    account
    run_reminders(on: due_date - 3.days)

    open_admin_home

    expect(page).to have_content(upcoming_title)
    expect(page).to have_content(payment_description("vence"))
    # Requiere acción (subir el comprobante): no se puede cerrar.
    expect(page).to have_no_button("Cerrar notificación")
  end

  it "todavía no avisa cuatro días antes del vencimiento" do
    account
    run_reminders(on: due_date - 4.days)

    open_admin_home

    expect(page).to have_no_content(upcoming_title)
    expect(page).to have_no_content(overdue_title)
  end

  it "el mismo día del vencimiento sigue mostrando el aviso de que se aproxima" do
    account
    run_reminders(on: due_date)

    open_admin_home

    expect(page).to have_content(upcoming_title)
    expect(page).to have_no_content(overdue_title)
  end

  it "avisa cuando el pago ya venció, reemplazando el aviso de que se aproximaba" do
    account
    run_reminders(on: due_date - 3.days)
    run_reminders(on: due_date + 1.day)

    open_admin_home

    expect(page).to have_content(overdue_title)
    expect(page).to have_content(payment_description("venció"))
    expect(page).to have_no_content(upcoming_title)
  end

  it "mantiene el aviso tras recargar y volver a iniciar sesión" do
    account
    run_reminders(on: due_date + 1.day)

    open_admin_home
    expect(page).to have_content(overdue_title)

    refresh
    expect(page).to have_content(overdue_title)

    sign_out
    open_admin_home
    expect(page).to have_content(overdue_title)
  end

  it "se lo muestra a todos los admins de la empresa" do
    second_admin = User.create!(email: "second-admin@example.com", name: "Otra RRHH GoGrow", password: "password123456")
    Admin.create!(user: second_admin, company:)
    account
    run_reminders(on: due_date - 3.days)

    open_admin_home(second_admin)

    expect(page).to have_content(upcoming_title)
    expect(page).to have_content(payment_description("vence"))
  end

  it "no le avisa a RR.HH. de otra empresa" do
    acme = Company.create!(name: "Acme", address: "Rivera 1234")
    acme_admin = User.create!(email: "acme-admin@example.com", name: "Acme RRHH", password: "password123456")
    Admin.create!(user: acme_admin, company: acme)
    account
    run_reminders(on: due_date - 3.days)

    open_admin_home(acme_admin)

    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(upcoming_title)
  end

  describe "permisos" do
    it "no le muestra el aviso al empleado ni al proveedor en su propio inicio" do
      account
      run_reminders(on: due_date - 3.days)

      sign_in users(:one), role: :consumer
      visit dashboard_path
      expect(page).to have_content("Hola,")
      expect(page).to have_no_content(upcoming_title)
      sign_out

      sign_in users(:provider_user), role: :provider
      visit provider_dashboard_path
      expect(page).to have_no_content(upcoming_title)
    end
  end
end
