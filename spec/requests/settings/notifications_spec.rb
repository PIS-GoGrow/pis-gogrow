# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings::Notifications", type: :request do
  fixtures :users, :providers

  ADMIN_CONFIGURATION_KEYS = %w[
    company_payments
    employee_debts
    hr_partial_payments
    hr_pending_invoices
    hr_pending_payments
    hr_rejected_receipts
    hr_subsidy_changes
  ].freeze

  let(:employee) { users(:one) }
  let(:other_employee) { users(:other_consumer_user) }
  let(:order_updates) { Notification::Configuration.find_by!(key: "order_updates") }

  describe "GET /settings/notifications" do
    it "le muestra al empleado solo los grupos configurables de su rol, apagados al principio" do
      sign_in employee, role: :consumer

      get settings_notifications_path

      expect(response).to have_http_status(:success)
      expect(inertia).to have_props { |props|
        props[:notification_configurations].map { it[:key] } == [ "order_updates" ] && props[:subscribed_keys] == []
      }
    end

    it "no le muestra al empleado un grupo de su rol que no es configurable" do
      create(:notification_configuration, key: "no_configurable", roles: %w[consumer], configurable: false)
      sign_in employee, role: :consumer

      get settings_notifications_path

      expect(inertia).to have_props { |props| props[:notification_configurations].none? { it[:key] == "no_configurable" } }
    end

    it "marca como prendidos los grupos a los que está suscrito" do
      order_updates.users << employee
      sign_in employee, role: :consumer

      get settings_notifications_path

      expect(inertia).to have_props(subscribed_keys: [ "order_updates" ])
    end

    it "no cuenta la suscripción de otro empleado" do
      order_updates.users << other_employee
      sign_in employee, role: :consumer

      get settings_notifications_path

      expect(inertia).to have_props(subscribed_keys: [])
    end

    it "al admin le muestra solo los grupos configurables de RRHH" do
      sign_in users(:admin), role: :admin

      get settings_notifications_path

      expect(inertia).to have_props { |props|
        props[:notification_configurations].map { it[:key] }.sort == ADMIN_CONFIGURATION_KEYS
      }
    end

    it "al proveedor le muestra sus grupos configurables, incluido cancelaciones, apagados al principio" do
      sign_in users(:provider_user), role: :provider

      get settings_notifications_path

      expect(inertia).to have_props { |props|
        keys = props[:notification_configurations].map { it[:key] }
        keys.sort == %w[menu_publication_reminders order_cancellations provider_orders provider_payments] &&
          props[:subscribed_keys] == []
      }
    end

    it "redirige al login sin sesión" do
      get settings_notifications_path

      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "PATCH /settings/notifications/:id" do
    before { sign_in employee, role: :consumer }

    it "prender suscribe al empleado en sesión" do
      patch settings_notification_path(order_updates), params: { subscribe: true }, as: :json

      expect(response).to redirect_to(settings_notifications_path)
      expect(order_updates.reload.users).to contain_exactly(employee)
    end

    it "apagar lo desuscribe" do
      order_updates.users << employee

      patch settings_notification_path(order_updates), params: { subscribe: false }, as: :json

      expect(response).to redirect_to(settings_notifications_path)
      expect(order_updates.reload.users).to be_empty
    end

    it "apagar no toca la suscripción de otro empleado" do
      order_updates.users << employee
      order_updates.users << other_employee

      patch settings_notification_path(order_updates), params: { subscribe: false }, as: :json

      expect(order_updates.reload.users).to contain_exactly(other_employee)
    end

    it "redirige al login sin sesión y no guarda nada" do
      sign_out

      patch settings_notification_path(order_updates), params: { subscribe: true }, as: :json

      expect(response).to redirect_to(sign_in_path)
      expect(order_updates.reload.users).to be_empty
    end

    it "muestra un error cuando la configuración no pertenece al rol" do
      patch settings_notification_path(999_999), params: { subscribe: true }, as: :json

      expect(response).to redirect_to(settings_notifications_path)
      expect(flash[:alert]).to eq(I18n.t("flash.config_update_error"))
    end
  end

  describe "PATCH /settings/notifications/:id as RRHH" do
    let(:admin) { users(:admin) }
    let(:pending_invoices) { Notification::Configuration.find_by!(key: "hr_pending_invoices") }

    before { sign_in admin, role: :admin }

    it "guarda y recupera una nueva preferencia" do
      patch settings_notification_path(pending_invoices), params: { subscribe: true }, as: :json

      expect(response).to redirect_to(settings_notifications_path)
      expect(flash[:notice]).to eq(I18n.t("flash.config_update"))
      expect(pending_invoices.reload.users).to include(admin)

      get settings_notifications_path

      expect(inertia).to have_props { |props| props[:subscribed_keys].include?("hr_pending_invoices") }
    end

    it "no lo suscribe a una configuración que existe pero es de otro rol" do
      patch settings_notification_path(order_updates), params: { subscribe: true }, as: :json

      expect(response).to redirect_to(settings_notifications_path)
      expect(flash[:alert]).to eq(I18n.t("flash.config_update_error"))
      expect(order_updates.reload.users).to be_empty
    end

    it "informa el error si no se pudo guardar y no deja la suscripción a medias" do
      allow(Notification::Configuration).to receive(:for_role).and_raise(ActiveRecord::ConnectionNotEstablished)

      patch settings_notification_path(pending_invoices), params: { subscribe: true }, as: :json

      expect(response).to redirect_to(settings_notifications_path)
      expect(flash[:alert]).to eq(I18n.t("flash.config_update_error"))
      expect(pending_invoices.reload.users).to be_empty
    end
  end

  describe "PATCH /settings/notifications/:id como proveedor" do
    let(:provider) { providers(:tuviandita) }
    let(:provider_config) { Notification::Configuration.find_by!(key: "provider_orders") }

    before do
      provider.update_column(:notifications_configured_at, nil)
      sign_in users(:provider_user), role: :provider
    end

    it "marca las notificaciones como configuradas al togglear, incluso al apagarlas" do
      patch settings_notification_path(provider_config), params: { subscribe: false }, as: :json

      expect(provider.reload.notifications_configured_at).to be_present
    end
  end
end
