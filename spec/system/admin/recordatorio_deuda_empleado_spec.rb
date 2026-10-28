# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recordatorio de deuda vencida enviado por Recursos Humanos", type: :system do
  fixtures :users, :companies, :admins, :providers, :consumers, :accounts, :payments

  let(:admin_user) { users(:admin) }
  let(:consumer) { consumers(:one) }
  let(:overdue_day) { accounts(:one_tuviandita_current).due_date + 1.day }

  before do
    Notification::Configuration.find_or_create_by!(key: "hr_payment_reminders") do |config|
      config.roles = [ "consumer" ]
    end
  end

  it "permite a RR. HH. recordar la deuda y muestra al empleado los proveedores acreedores" do
    travel_to overdue_day do
      sign_in admin_user, role: :admin
      visit_hydrated admin_consumer_path(consumer)

      expect(page).to have_content("Detalle del empleado")
      expect(page).to have_button("Recordar pago pendiente")

      click_button "Recordar pago pendiente"

      within("[role='dialog']") do
        expect(page).to have_content("Recordar pago pendiente")
        expect(page).to have_content("Se le va a enviar un recordatorio a Test User por sus pagos vencidos")
        click_button "Enviar recordatorio"

        expect(page).to have_content("Recordatorio enviado")
        click_button "Listo"
      end

      sign_out

      sign_in consumer.user, role: :consumer
      visit_hydrated dashboard_path

      expect(page).to have_content("Recordatorio de pago pendiente")
      expect(page).to have_content(
        "Recursos Humanos te recuerda que tenés $950,75 en pagos vencidos con Other Provider User y Provider User. Podés verlos en tus pagos."
      )

      click_button "Cerrar notificación"
      expect(page).to have_no_content("Recordatorio de pago pendiente")
    end
  end

  it "muestra un único proveedor cuando la deuda vencida es con un solo acreedor" do
    accounts(:one_endulzate_current).destroy!

    travel_to overdue_day do
      sign_in admin_user, role: :admin
      visit_hydrated admin_consumer_path(consumer)

      click_button "Recordar pago pendiente"

      within("[role='dialog']") do
        click_button "Enviar recordatorio"
        expect(page).to have_content("Recordatorio enviado")
        click_button "Listo"
      end

      sign_out

      sign_in consumer.user, role: :consumer
      visit_hydrated dashboard_path

      within("[role='alert']") do
        expect(page).to have_content("Recordatorio de pago pendiente")
        expect(page).to have_content(
          "Recursos Humanos te recuerda que tenés $450,75 en pagos vencidos con Provider User. Podés verlos en tus pagos."
        )
        expect(page).to have_no_content(" y ")
      end
    end
  end
end
