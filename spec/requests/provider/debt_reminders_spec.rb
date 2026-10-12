# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Provider::DebtReminders", type: :request do
  fixtures :users, :companies, :providers, :consumers, :accounts, :payments

  let(:provider_user) { users(:provider_user) }
  let(:other_provider_user) { users(:other_provider_user) }
  let(:consumer_user) { users(:one) }
  let(:admin_user) { users(:admin) }
  let(:consumer_account) { accounts(:one_tuviandita_current) }
  let(:other_provider_account) { accounts(:one_endulzate_current) }
  let(:company_account) { accounts(:gogrow_tuviandita_current) }

  before do
    Notification::Configuration.find_or_create_by!(key: "provider_payment_reminders") do |c|
      c.roles = [ "consumer" ]
    end
    consumer_account.update!(amount: 150)
  end

  describe "POST /provider/collections/:collection_id/debt_reminders" do
    context "Control de acceso por rol y autenticación" do
      it "redirige al inicio de sesión cuando no hay sesión activa" do
        post provider_collection_debt_reminders_path(consumer_account)
        expect(response).to redirect_to(sign_in_path)
      end

      it "redirige al inicio (root) cuando el usuario es un consumidor" do
        sign_in consumer_user, role: :consumer
        post provider_collection_debt_reminders_path(consumer_account)
        expect(response).to redirect_to(root_path)
      end

      it "redirige al inicio (root) cuando el usuario es un administrador" do
        sign_in admin_user, role: :admin
        post provider_collection_debt_reminders_path(consumer_account)
        expect(response).to redirect_to(root_path)
      end

      it "devuelve 404 si el proveedor intenta recordar sobre una cuenta de otro proveedor" do
        sign_in other_provider_user, role: :provider
        post provider_collection_debt_reminders_path(consumer_account)
        expect(response).to have_http_status(:not_found)
      end

      it "devuelve 404 ante un ID de cuenta inexistente" do
        sign_in provider_user, role: :provider
        post provider_collection_debt_reminders_path(collection_id: 999_999_999)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "Flujo exitoso" do
      it "crea la notificación para el empleado y redirige con status see_other" do
        sign_in provider_user, role: :provider
        travel_to consumer_account.due_date + 1.day do
          expect {
            post provider_collection_debt_reminders_path(consumer_account),
                 headers: { "HTTP_REFERER" => provider_collections_path }
          }.to change(Notification, :count).by(1)

          expect(response).to have_http_status(:see_other)
          expect(response).to redirect_to(provider_collections_path)

          notification = Notification.last
          expect(notification.user).to eq(consumer_user)
          expect(notification.event).to eq(DebtReminders::Eligibility::EVENT)
          expect(notification.notifiable).to eq(consumer_account)
        end
      end
    end

    context "Validación de casos de ineligibilidad (bypass de interfaz o llamadas directas)" do
      before do
        sign_in provider_user, role: :provider
      end

      it "devuelve error de validación cuando la cuenta no está vencida" do
        travel_to consumer_account.due_date - 1.day do
          expect {
            post provider_collection_debt_reminders_path(consumer_account),
                 headers: { "HTTP_REFERER" => provider_collections_path }
          }.not_to change(Notification, :count)

          expect(response).to have_http_status(:see_other)
          expect(response).to redirect_to(provider_collections_path)
          follow_redirect!
          expect(inertia).to have_props(errors: { debt_reminder: [ I18n.t("validations.debt_reminder_not_overdue") ] })
        end
      end

      it "devuelve error cuando la cuenta es de una empresa" do
        company_account.update!(amount: 500)
        travel_to company_account.due_date + 1.day do
          expect {
            post provider_collection_debt_reminders_path(company_account),
                 headers: { "HTTP_REFERER" => provider_collections_path }
          }.not_to change(Notification, :count)

          expect(response).to have_http_status(:see_other)
          follow_redirect!
          expect(inertia).to have_props(errors: { debt_reminder: [ I18n.t("validations.debt_reminder_not_consumer") ] })
        end
      end

      it "devuelve error cuando la cuenta ya está en cooldown (menos de 3 días)" do
        travel_to consumer_account.due_date + 1.day do
          post provider_collection_debt_reminders_path(consumer_account),
               headers: { "HTTP_REFERER" => provider_collections_path }
          expect(response).to have_http_status(:see_other)

          # Intento inmediato de bypass del frontend
          expect {
            post provider_collection_debt_reminders_path(consumer_account),
                 headers: { "HTTP_REFERER" => provider_collections_path }
          }.not_to change(Notification, :count)

          expect(response).to have_http_status(:see_other)
          follow_redirect!
          expect(inertia).to have_props(errors: { debt_reminder: [ I18n.t("validations.debt_reminder_cooldown") ] })
        end
      end

      it "devuelve error cuando la cuenta tiene un comprobante enviado en revisión" do
        submitted_account = accounts(:other_tuviandita_current)
        submitted_account.update!(amount: 150)
        travel_to submitted_account.due_date + 1.day do
          expect {
            post provider_collection_debt_reminders_path(submitted_account),
                 headers: { "HTTP_REFERER" => provider_collections_path }
          }.not_to change(Notification, :count)

          expect(response).to have_http_status(:see_other)
          follow_redirect!
          expect(inertia).to have_props(errors: { debt_reminder: [ I18n.t("validations.debt_reminder_payment_under_review") ] })
        end
      end
    end
  end
end
