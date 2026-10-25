# frozen_string_literal: true

# Historia IBP-027 "Como EMPLEADO, quiero recibir una notificación cuando el plazo
# de pago del mes esté por vencer para poder organizar mis pagos." La parte que ve
# el empleado: el banner en el inicio (CA1, CA2), descartarlo (CA5) y que se cierre
# solo al presentar el comprobante (CA4). Las reglas de fecha, duplicados y estados
# están en spec/services/payment_reminders/generate_spec.rb.

require "rails_helper"

RSpec.describe "Recordatorio de vencimiento de pago", type: :system do
  fixtures :users, :consumers, :companies, :providers, :accounts

  let(:account) { accounts(:one_tuviandita_current) }
  let(:title) { "Tu pago vence pronto..." }

  before do
    Notification::Configuration.find_or_create_by!(key: "automatic_payment_reminders") do |configuration|
      configuration.roles = %w[consumer]
    end
    page.current_window.resize_to(1400, 1400)

    consumers(:one).accounts.where.not(id: account.id).destroy_all
    Payment.where(account:).destroy_all
    account.update!(month: Date.current.prev_month.beginning_of_month)
  end

  # Lo que hace el job de la 1 de la mañana el día del aviso: 3 días antes del vencimiento.
  def run_reminders
    PaymentReminders::Generate.call(date: account.due_date - 3.days)
  end

  def visit_dashboard_as(user)
    sign_in user, role: :consumer
    visit dashboard_path
    expect(page).to have_content("Hola,")
  end

  it "le muestra al empleado el proveedor, el monto y la fecha de vencimiento" do
    run_reminders

    visit_dashboard_as users(:one)

    expect(page).to have_content(title)
    expect(page).to have_content(
      "Te quedan 3 días para pagar $450,75 a #{account.provider.user.name}. " \
      "Vence el #{DateFormat.long(account.due_date, inline: true)}. ¡Revisá el detalle de tu pago!"
    )
  end

  it "no vuelve a aparecer después de descartarlo, ni al recargar, ni al volver a entrar, ni al correr el job de nuevo" do
    run_reminders
    visit_dashboard_as users(:one)

    click_button "Cerrar notificación"
    expect(page).to have_no_content(title)

    visit dashboard_path
    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(title)

    sign_out
    run_reminders
    visit_dashboard_as users(:one)
    expect(page).to have_no_content(title)
  end

  it "desaparece cuando el empleado presenta el comprobante" do
    run_reminders
    visit_dashboard_as users(:one)
    expect(page).to have_content(title)

    visit accounts_path
    within(find("[role=tabpanel]")) { click_on I18n.t("pages.accounts.show.receipt") }
    within(find("[role=dialog]")) do
      attach_file(I18n.t("pages.accounts.show.receipt_file"), Rails.root.join("public/icon.png").to_s)
      click_on I18n.t("pages.accounts.show.receipt")
    end
    expect(page).to have_content(I18n.t("pages.accounts.show.receipt_success_title"))

    visit dashboard_path
    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(title)
  end

  it "no se le muestra a otro empleado" do
    run_reminders

    visit_dashboard_as users(:other_consumer_user)

    expect(page).to have_no_content(title)
  end
end
