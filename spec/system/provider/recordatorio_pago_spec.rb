# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recordatorio de pago pendiente", type: :system do
  fixtures :users, :companies, :providers, :consumers, :accounts, :payments

  let(:provider) { providers(:tuviandita) }
  let(:provider_user) { users(:provider_user) }
  let(:employee_user) { users(:one) }
  let(:consumer_account) { accounts(:one_tuviandita_current) }

  before do
    Notification::Configuration.find_or_create_by!(key: "provider_payment_reminders") do |c|
      c.roles = [ "consumer" ]
    end
    # Asegurar que la cuenta tiene deuda y es del mes anterior para que esté vencida hoy
    consumer_account.update!(
      month: Date.current.prev_month.beginning_of_month,
      amount: 450.75
    )
    # Limpiar pagos previos sobre esta cuenta para que quede en estado pending
    consumer_account.payments.destroy_all
  end

  it "permite al proveedor recordar el pago de una deuda vencida elegible y luego entra en cooldown" do
    # due_date = month.next_month.change(day: 10)
    # Estando en el mes anterior, hoy en Date.current ya está vencida
    sign_in provider_user, role: :provider

    visit provider_collections_path

    # En la pantalla de cobros, seleccionar clientes/empleados del grupo del mes anterior
    previous_month_label = I18n.l(Date.current.prev_month, format: :month_name_year)
    within(find("[role=tabpanel] [data-slot=card]", text: previous_month_label)) do
      click_on "Empleados"
      expect(page).to have_content(employee_user.name)
      click_on employee_user.name
    end

    # Verificar que aparece la opción de recordar pago
    expect(page).to have_button(I18n.t("pages.provider_collections.reminder.trigger"))

    click_on I18n.t("pages.provider_collections.reminder.trigger")

    # Diálogo de confirmación
    within("[role=dialog]") do
      expect(page).to have_content(I18n.t("pages.provider_collections.reminder.confirm.title"))
      expect(page).to have_content(employee_user.name)

      click_on I18n.t("pages.provider_collections.reminder.send")

      # Feedback de éxito
      expect(page).to have_content(I18n.t("pages.provider_collections.reminder.success.title"))
      click_on I18n.t("pages.provider_collections.reminder.done")
    end

    # La notificación debió crearse en la base de datos para el empleado
    notification = Notification.last
    expect(notification.user).to eq(employee_user)
    expect(notification.event).to eq(DebtReminders::Eligibility::EVENT)
    expect(notification.notifiable).to eq(consumer_account)

    # Ahora debe mostrarse el mensaje de cooldown en la cuenta
    expect(page).to have_content("Podés enviar otro recordatorio el")
    expect(page).not_to have_button(I18n.t("pages.provider_collections.reminder.trigger"))
  end

  it "cierra el recordatorio de pago pendiente en el panel del empleado cuando el proveedor aprueba el comprobante" do
    Notifier.call(
      event_key: DebtReminders::Eligibility::EVENT,
      user: employee_user,
      notifiable: consumer_account,
      description_data: {
        amount: "$450,75",
        provider: provider.user.name,
        period: I18n.l(consumer_account.month, format: :month_name_year)
      }
    )

    # 1. El empleado ve la notificación activa en su inicio
    sign_in employee_user, role: :consumer
    visit dashboard_path
    expect(page).to have_content("Recordatorio de pago pendiente")

    # 2. El empleado sube el comprobante correspondiente a esa cuenta
    visit accounts_path
    within(find("[role=tabpanel]")) { click_on I18n.t("pages.accounts.show.receipt") }
    within(find("[role=dialog]")) do
      attach_file(I18n.t("pages.accounts.show.receipt_file"), Rails.root.join("public/icon.png").to_s)
      click_on I18n.t("pages.accounts.show.receipt")
    end
    expect(page).to have_content(I18n.t("pages.accounts.show.receipt_success_title"))

    # 3. La notificación sigue visible mientras el comprobante está en revisión
    visit dashboard_path
    expect(page).to have_content("Recordatorio de pago pendiente")

    # 4. El proveedor ingresa y aprueba el comprobante
    sign_out
    sign_in provider_user, role: :provider
    visit provider_collections_path

    previous_month_label = I18n.l(Date.current.prev_month, format: :month_name_year)
    within(find("[role=tabpanel] [data-slot=card]", text: previous_month_label)) do
      click_on "Empleados"
      expect(page).to have_content(employee_user.name)
      click_on employee_user.name
    end

    click_on "Revisar pago"
    within(find("[role=dialog]")) { click_on "Aprobar" }
    expect(page).to have_content(I18n.t("pages.provider_collections.review.approved_title"))
    click_on I18n.t("pages.provider_collections.review.done")

    # 5. El empleado vuelve a ingresar y la notificación ya no se muestra
    sign_out
    sign_in employee_user, role: :consumer
    visit dashboard_path
    expect(page).to have_no_content("Recordatorio de pago pendiente")
  end
end
