# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notifications", type: :request do
  let!(:notification_configuration) do
    Notification::Configuration.find_or_create_by!(key: "order_updates") do |configuration|
      configuration.roles = %w[consumer]
    end
  end

  let(:company) do
    Company.create!(name: "GoGrow", address: "18 de Julio 1006")
  end

  let(:user) do
    User.create!(
      email: "consumer-notifications@gmail.com",
      name: "Sofía",
      password: "password123456"
    )
  end

  let!(:consumer) do
    Consumer.create!(user:, company:, address: "Ellauri 1234").tap do
      user.reload
    end
  end

  def sign_in(user)
    session = user.sessions.create!(role: :consumer)
    cookies[:session_token] =
      AuthenticationHelpers.signed_cookie(:session_token, session.id)
  end

  def create_notification(user:, notifiable: user)
    Notification.create!(
      notification_configuration: notification_configuration,
      user:,
      role: "consumer",
      event: "order_confirmation",
      requires_action: false,
      notifiable:,
      title: "Tu pedido fue confirmado",
      description: "Tu pedido fue confirmado."
    )
  end

  describe "PATCH /notificaciones/:id/cerrar" do
    it "closes an active dismissable notification belonging to the current user" do
      notification = create_notification(user:)
      sign_in(user)

      patch close_notification_path(notification)

      expect(response).to have_http_status(:see_other)
      expect(notification.reload.closed_at).to be_present
    end

    it "does not close a notification that requires action" do
      notification = create_notification(user:)
      notification.update_column(:requires_action, true)
      sign_in(user)

      patch close_notification_path(notification)

      expect(response).to have_http_status(:not_found)
      expect(notification.reload.closed_at).to be_nil
    end

    it "does not close another user's notification" do
      other_user = User.create!(
        email: "other-consumer-notifications@gmail.com",
        name: "Martín",
        password: "password123456"
      )
      Consumer.create!(
        user: other_user,
        company:,
        address: "Colonia 1234"
      )

      other_user.reload
      notification = create_notification(user: other_user)

      sign_in(user)

      patch close_notification_path(notification)

      expect(response).to have_http_status(:not_found)
      expect(notification.reload.closed_at).to be_nil
    end

    it "does not close an employee notification from a provider session of the same user" do
      Provider.create!(user:)
      notification = create_notification(user:)
      session = user.sessions.create!(role: :provider)
      cookies[:session_token] = AuthenticationHelpers.signed_cookie(:session_token, session.id)

      patch close_notification_path(notification)

      expect(response).to have_http_status(:not_found)
      expect(notification.reload.closed_at).to be_nil
    end

    context "cuando el usuario no está autenticado" do
      it "redirecciona al inicio de sesión" do
        notification = create_notification(user:)

        patch close_notification_path(notification)

        expect(response).to have_http_status(:redirect)
        expect(notification.reload.closed_at).to be_nil
      end
    end

    context "con bypass de interfaz o parámetros inválidos" do
      before { sign_in(user) }

      it "devuelve 404 para un id inexistente" do
        patch close_notification_path(id: 999_999)

        expect(response).to have_http_status(:not_found)
      end

      it "devuelve 404 para un id no numérico o inválido" do
        patch "/notificaciones/invalido/cerrar"

        expect(response).to have_http_status(:not_found)
      end

      it "devuelve 404 al intentar cerrar una notificación que ya fue cerrada" do
        notification = create_notification(user:)
        notification.close!

        patch close_notification_path(notification)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "Inertia shared props :notifications" do
    it "envía las notificaciones activas del rol de la sesión con la estructura esperada" do
      closed_notification = create_notification(user:)
      closed_notification.close!
      active_notification = create_notification(user:)
      sign_in(user)

      get dashboard_path

      expect(response).to have_http_status(:ok)
      notifications_prop = inertia.props[:notifications]
      expect(notifications_prop).to be_an(Array)
      expect(notifications_prop.size).to eq(1)
      expect(notifications_prop.first).to match(
        a_hash_including(
          id: active_notification.id,
          title: "Tu pedido fue confirmado",
          description: "Tu pedido fue confirmado.",
          requires_action: false
        )
      )
      expect(notifications_prop.map { |n| n[:id] }).not_to include(closed_notification.id)
    end
  end
end
