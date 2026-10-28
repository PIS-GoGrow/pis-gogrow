# frozen_string_literal: true

# Historia IBP-112 "Como EMPLEADO, quiero recibir una notificación cuando se habilita
# el período para realizar un pago pendiente, para saber desde qué momento puedo
# abonarlo y cuál es su fecha límite." La parte que ve el empleado en el inicio
# (CA1, CA2, CA5, CA6). Las reglas de fecha, duplicados y estados están en
# spec/services/payment_reminders/generate_spec.rb.

require "rails_helper"

RSpec.describe "Aviso de apertura del período de pago", type: :system do
  fixtures :users, :consumers, :companies, :providers, :accounts

  let(:account) { accounts(:one_tuviandita_current) }
  let(:other_provider_account) { accounts(:one_endulzate_current) }
  let(:title) { "¡Ya podés realizar tu pago!" }
  let(:previous_month) { Date.current.prev_month.beginning_of_month }

  before do
    Notification::Configuration.find_or_create_by!(key: "automatic_payment_reminders") do |configuration|
      configuration.roles = %w[consumer]
    end
    page.current_window.resize_to(1400, 1400)

    consumers(:one).accounts.where.not(id: [ account.id, other_provider_account.id ]).destroy_all
    Payment.where(account: [ account, other_provider_account ]).destroy_all
    account.update!(month: previous_month)
  end

  def run_reminders(date: previous_month.next_month)
    PaymentReminders::Generate.call(date:)
  end

  def visit_dashboard
    sign_in users(:one), role: :consumer
    visit dashboard_path
    expect(page).to have_content("Hola,")
  end

  def due_date_text(account)
    DateFormat.long(account.due_date, inline: true)
  end

  context "con deuda en un solo proveedor" do
    before { other_provider_account.destroy! }

    it "le muestra al empleado el proveedor, el monto y el vencimiento del día 10" do
      run_reminders
      visit_dashboard

      expect(page).to have_content(title)
      expect(page).to have_content(
        "Ya podés pagar $450,75 a #{account.provider.user.name}. " \
        "El vencimiento es el #{due_date_text(account)}. ¡Revisá el detalle de tu pago!"
      )
      expect(account.due_date.day).to eq(10)
    end

    it "sigue mostrándose mientras no paga y desaparece al presentar el comprobante" do
      run_reminders
      visit_dashboard
      expect(page).to have_content(title)

      sign_out
      run_reminders(date: previous_month.next_month + 1.day)
      visit_dashboard
      expect(page).to have_content(title)

      visit_hydrated accounts_path
      within(find("[role=tabpanel]")) do
        attach_file(I18n.t("pages.accounts.show.receipt_file"), Rails.root.join("public/icon.png").to_s)
        click_on I18n.t("pages.accounts.show.receipt")
      end
      expect(page).to have_content(I18n.t("pages.accounts.show.receipt_success_title"))

      visit dashboard_path
      expect(page).to have_content("Hola,")
      expect(page).to have_no_content(title)
    end

    it "no vuelve a aparecer después de descartarlo, ni al recargar, ni al volver a entrar, ni al correr el job de nuevo" do
      run_reminders
      visit_dashboard

      click_button "Cerrar notificación"
      expect(page).to have_no_content(title)

      visit dashboard_path
      expect(page).to have_content("Hola,")
      expect(page).to have_no_content(title)

      sign_out
      run_reminders
      visit_dashboard
      expect(page).to have_no_content(title)
    end
  end

  it "muestra un aviso por cada proveedor al que le debe" do
    other_provider_account.update!(month: previous_month)

    run_reminders
    visit_dashboard

    expect(page).to have_content(title, count: 2)
    expect(page).to have_content("Ya podés pagar $450,75 a #{account.provider.user.name}.")
    expect(page).to have_content("Ya podés pagar $500 a #{other_provider_account.provider.user.name}.")
  end
end
