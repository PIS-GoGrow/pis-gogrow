# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recordatorios de publicación", type: :request do
  fixtures :users, :providers, :menus

  let(:provider) { providers(:tuviandita) }
  let(:menu) { menus(:milanesa) }
  let(:event) { "provider_menu_unpublished" }

  before do
    travel_to Time.zone.local(2030, 1, 9, 10)
    ProviderMenuUnpublishedRemindersJob.perform_now
    sign_in(provider.user, role: :provider)
  end

  it "expone solamente los recordatorios del proveedor autenticado" do
    notification = provider.user.notifications.find_by!(event:)

    get provider_dashboard_path

    expect(inertia).to have_props(notifications: [ { id: notification.id, title: notification.title, description: notification.description, requires_action: true } ])
  end

  it "cierra el recordatorio al publicar desde el endpoint y no lo recrea" do
    notification = provider.user.notifications.find_by!(event:)

    post publish_provider_menus_path, params: { menu_ids: [ menu.id ], date: Date.current.iso8601 }

    expect(response).to have_http_status(:redirect)
    follow_redirect!
    expect(inertia).to have_props(notifications: [])
    expect(notification.reload.closed_at).to be_present
    expect { ProviderMenuUnpublishedRemindersJob.perform_now }.not_to change(Notification, :count)
  end

  it "mantiene el recordatorio ante una publicación inválida" do
    notification = provider.user.notifications.find_by!(event:)

    post publish_provider_menus_path, params: { menu_ids: [ menus(:sorrentinos).id ], date: Date.current.iso8601 }

    expect(response).to have_http_status(:redirect)
    expect(notification.reload.closed_at).to be_nil
  end

  it "no permite cerrar el recordatorio de otro proveedor" do
    notification = providers(:endulzate).user.notifications.find_by!(event:)

    patch close_notification_path(notification)

    expect(response).to have_http_status(:not_found)
    expect(notification.reload.closed_at).to be_nil
  end
end
