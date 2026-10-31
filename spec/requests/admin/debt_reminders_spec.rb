# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::DebtReminders", type: :request do
  fixtures :users, :companies, :admins, :consumers, :providers, :accounts, :payments

  let(:admin_user) { users(:admin) }
  let(:consumer) { consumers(:one) }
  let(:overdue_day) { accounts(:one_tuviandita_current).due_date + 1.day }

  before do
    Notification::Configuration.find_or_create_by!(key: "hr_payment_reminders") do |config|
      config.roles = [ "consumer" ]
    end
  end

  describe "POST /admin/empleados/:consumer_id/recordatorios-de-deuda" do
    it "redirige al inicio de sesión cuando no hay sesión activa" do
      post admin_consumer_debt_reminders_path(consumer)

      expect(response).to redirect_to(admin_welcome_path)
    end

    it "redirige al inicio cuando el usuario es un empleado" do
      sign_in users(:one), role: :consumer

      post admin_consumer_debt_reminders_path(consumer)

      expect(response).to redirect_to(root_path)
    end

    it "redirige al inicio cuando el usuario es un proveedor" do
      sign_in users(:provider_user), role: :provider

      post admin_consumer_debt_reminders_path(consumer)

      expect(response).to redirect_to(root_path)
    end

    it "devuelve 404 ante un empleado de otra empresa" do
      other_company = Company.create!(name: "Otra empresa", address: "Rincón 500")
      other_user = User.create!(name: "Ajeno", email: "ajeno@example.com", password: "Secret1*3*5*")
      other_consumer = Consumer.create!(company: other_company, user: other_user, address: "Yí 1234")
      sign_in admin_user, role: :admin

      post admin_consumer_debt_reminders_path(other_consumer)

      expect(response).to have_http_status(:not_found)
    end

    it "devuelve 404 ante un ID de empleado inexistente" do
      sign_in admin_user, role: :admin

      post admin_consumer_debt_reminders_path(consumer_id: 999_999)

      expect(response).to have_http_status(:not_found)
    end

    it "devuelve 404 ante un parámetro de ruta inválido" do
      sign_in admin_user, role: :admin

      post "/rrhh/empleados/bypass/recordatorios-de-deuda"

      expect(response).to have_http_status(:not_found)
    end

    context "cuando lo manda Recursos Humanos" do
      before { sign_in admin_user, role: :admin }

      it "crea una sola notificación por toda la deuda vencida" do
        travel_to overdue_day do
          expect {
            post admin_consumer_debt_reminders_path(consumer),
                 headers: { "HTTP_REFERER" => admin_consumer_path(consumer) }
          }.to change(Notification, :count).by(1)

          expect(response).to have_http_status(:see_other)
          expect(response).to redirect_to(admin_consumer_path(consumer))

          notification = Notification.last
          expect(notification.user).to eq(consumer.user)
          expect(notification.event).to eq(DebtReminders::EmployeeEligibility::EVENT)
          expect(notification.notifiable).to eq(consumer)
          expect(notification.description).to include("con Other Provider User y Provider User.")
          expect(notification.description).to include("$950,75")
        end
      end

      it "expone la notificación con los proveedores en las props de Inertia para el empleado" do
        travel_to overdue_day do
          post admin_consumer_debt_reminders_path(consumer),
               headers: { "HTTP_REFERER" => admin_consumer_path(consumer) }

          sign_in consumer.user, role: :consumer
          get dashboard_path

          expect(response).to have_http_status(:ok)
          expect(inertia.props[:notifications]).to include(
            hash_including(
              "title" => I18n.t("notifications.#{DebtReminders::EmployeeEligibility::EVENT}.title"),
              "requires_action" => false,
              "description" => a_string_including("con Other Provider User y Provider User.")
            )
          )
        end
      end

      it "avisa que hay que esperar cuando ya se mandó uno hace menos de tres días" do
        travel_to overdue_day do
          post admin_consumer_debt_reminders_path(consumer),
               headers: { "HTTP_REFERER" => admin_consumer_path(consumer) }

          expect {
            post admin_consumer_debt_reminders_path(consumer),
                 headers: { "HTTP_REFERER" => admin_consumer_path(consumer) }
          }.not_to change(Notification, :count)

          follow_redirect!
          expect(inertia).to have_props(
            errors: { debt_reminder: [ I18n.t("validations.debt_reminder_cooldown") ] }
          )
        end
      end

      it "avisa cuando el empleado no tiene deuda vencida" do
        travel_to accounts(:one_tuviandita_current).due_date - 1.day do
          expect {
            post admin_consumer_debt_reminders_path(consumer),
                 headers: { "HTTP_REFERER" => admin_consumer_path(consumer) }
          }.not_to change(Notification, :count)

          follow_redirect!
          expect(inertia).to have_props(
            errors: { debt_reminder: [ I18n.t("validations.debt_reminder_no_debt") ] }
          )
        end
      end
    end
  end

  describe "GET /admin/empleados/:id" do
    before { sign_in admin_user, role: :admin }

    it "manda el botón habilitado cuando hay deuda vencida" do
      travel_to overdue_day do
        get admin_consumer_path(consumer)

        expect(inertia.props[:debt_reminder]).to include("eligible" => true, "amount" => 950.75)
      end
    end

    it "manda el motivo del bloqueo cuando no se puede recordar" do
      travel_to accounts(:one_tuviandita_current).due_date - 1.day do
        get admin_consumer_path(consumer)

        expect(inertia.props[:debt_reminder])
          .to include("eligible" => false, "blocked_reason" => "no_debt")
      end
    end
  end
end
