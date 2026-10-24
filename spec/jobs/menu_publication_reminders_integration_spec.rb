# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Integración de recordatorios de menú", type: :job do
  include ActiveJob::TestHelper

  fixtures :users, :providers, :menus

  let(:provider) { providers(:tuviandita) }
  let(:event) { "provider_menu_unpublished" }
  let(:configuration) { Notification::Configuration.find_by!(key: "menu_publication_reminders") }

  before { travel_to Time.zone.local(2030, 1, 9, 10) }

  def run_reminders
    ProviderMenuUnpublishedRemindersJob.perform_now
  end

  it "no encola WhatsApp sin suscripción aunque muestra el aviso en la app" do
    expect { run_reminders }.not_to have_enqueued_job(WhatsappSenderJob)
    expect(provider.user.notifications.active.where(event:).count).to eq(1)
  end

  it "encola una sola entrega al teléfono del proveedor suscripto" do
    provider.user.update!(phone: "+59899123456")
    configuration.users << provider.user

    expect { 2.times { run_reminders } }.to have_enqueued_job(WhatsappSenderJob)
      .with(instance_of(Notification), :provider_menu_unpublished, {}, { date: "9/1/2030" }, "+59899123456").exactly(:once)
  end

  it "no genera avisos ni entregas durante el fin de semana" do
    configuration.users << provider.user
    travel_to Time.zone.local(2030, 1, 12, 10)

    expect { run_reminders }.not_to change(Notification, :count)
    expect(enqueued_jobs).to be_empty
  end

  it "usa el día de Montevideo cuando UTC ya está en el día siguiente" do
    travel_to Time.utc(2030, 1, 10, 1, 30)
    run_reminders
    notification = provider.user.notifications.find_by!(event:)

    expect(notification.description).to eq("Todavía no publicaste un menú para el 9/1/2030.")
    travel_to Time.utc(2030, 1, 10, 3, 5)
    ProviderMenuUnpublishedNotificationsCleanupJob.perform_now

    expect(notification.reload.closed_at).to be_present
  end

  it "conserva el aviso de hoy al limpiar el anterior y permite repetir la limpieza" do
    run_reminders
    previous = provider.user.notifications.find_by!(event:)
    travel_to Time.zone.local(2030, 1, 10, 10)
    run_reminders
    current = provider.user.notifications.active.find_by!(event:)

    2.times { ProviderMenuUnpublishedNotificationsCleanupJob.perform_now }

    expect(previous.reload.closed_at).to be_present
    expect(current.reload.closed_at).to be_nil
  end

  it "reintenta tras un fallo parcial sin duplicar los proveedores ya procesados" do
    calls = 0
    allow(Notifier).to receive(:call).and_wrap_original do |original, **arguments|
      calls += 1
      raise "fallo simulado" if calls == 2

      original.call(**arguments)
    end

    expect { run_reminders }.to raise_error("fallo simulado")
    run_reminders

    counts = Notification.where(event:).group(:notifiable_id).count
    expect(counts).to eq(Provider.where.not(user_id: nil).ids.index_with { 1 })
  end

  it "recupera el cierre si falla después de confirmar la publicación y se reintenta" do
    run_reminders
    notification = provider.user.notifications.active.find_by!(event:)
    menu = menus(:milanesa)
    publication = Menus::Publish.new(provider:, menu_ids: [ menu.id ], date: Date.current.iso8601)
    attempts = 0
    allow(Menus::MissingPublicationNotifier).to receive(:close_for).and_wrap_original do |original, **arguments|
      attempts += 1
      raise "fallo de cierre simulado" if attempts == 1

      original.call(**arguments)
    end

    expect { publication.call }.to raise_error("fallo de cierre simulado")
    expect(menu.schedules.where(date: Date.current)).to exist

    expect(publication.call).to be(true)
    run_reminders

    expect(notification.reload.closed_at).to be_present
  end

  it "reconcilia sin callback, sin duplicar ni cerrar avisos de otros eventos o menús faltantes" do
    run_reminders
    reminder = provider.user.notifications.active.find_by!(event:)
    other_reminder = providers(:endulzate).user.notifications.active.find_by!(event:)
    unrelated = Notification.create!(
      user: provider.user,
      notifiable: provider,
      notification_configuration: Notification::Configuration.find_by!(key: "provider_orders"),
      event: :order_received,
      role: :provider,
      requires_action: false,
      title: "Nuevo pedido",
      description: "Recibiste un pedido"
    )
    allow(Menus::MissingPublicationNotifier).to receive(:close_for)
    menus(:milanesa).schedules.create!(date: Date.current, amount: 10)
    menus(:sorrentinos).schedules.create!(date: Date.current, amount: 10)
    menus(:sorrentinos).update!(archived_at: Time.current)

    expect { 2.times { run_reminders } }.not_to change(Notification, :count)

    expect(reminder.reload.closed_at).to be_present
    expect(other_reminder.reload.closed_at).to be_nil
    expect(unrelated.reload.closed_at).to be_nil
  end
end
