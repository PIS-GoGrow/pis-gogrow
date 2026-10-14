# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::MissingPublicationNotifier do
  fixtures :users, :providers, :menus

  let(:provider) { providers(:tuviandita) }
  let(:menu) { menus(:milanesa) }
  let(:date) { Date.current }
  let(:providers_relation) { Provider.where(id: provider.id) }

  before { travel_to Time.zone.local(2030, 1, 9, 10, 0) }

  def call_notifier
    described_class.call(providers: providers_relation, date:)
  end

  def provider_notifications
    provider.user.notifications.where(event: described_class::EVENT, notifiable: provider)
  end

  it "notifies a provider without a published menu" do
    expect { call_notifier }.to change(Notification, :count).by(1)

    expect(provider_notifications.active.sole).to have_attributes(
      user: provider.user,
      role: "provider",
      requires_action: true,
      title: "Publicá el menú del día",
      description: "Todavía no publicaste un menú para el 9/1/2030."
    )
  end

  it "does not notify a provider with a published menu" do
    menu.schedules.create!(date:, amount: 10)

    expect { call_notifier }.not_to change(Notification, :count)
  end

  it "does not duplicate a notification across repeated runs" do
    2.times { call_notifier }

    expect(provider_notifications.count).to eq(1)
  end

  it "does not notify more than once on the same date after the first notification is closed" do
    call_notifier
    provider_notifications.sole.close!

    expect { call_notifier }.not_to change(provider_notifications, :count)
  end

  it "does not duplicate a notification across concurrent runs" do
    ready = Queue.new
    start = Queue.new
    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          call_notifier
        end
      end
    end

    2.times { ready.pop }
    2.times { start << true }
    threads.each(&:value)

    expect(provider_notifications.count).to eq(1)
  end

  it "closes the active notification when a valid schedule is published later" do
    call_notifier
    notification = provider_notifications.active.sole

    menu.schedules.create!(date:, amount: 0, available: false)

    expect(notification.reload.closed_at).to eq(Time.current)
  end

  it "keeps the notification active when a schedule belongs to an archived menu" do
    call_notifier
    notification = provider_notifications.active.sole
    menu.update!(archived_at: Time.current)

    menu.schedules.create!(date:, amount: 10)

    expect(notification.reload.closed_at).to be_nil
  end

  it "closes obsolete notifications before notifying for a new day" do
    call_notifier
    previous = provider_notifications.active.sole

    travel_to Time.zone.local(2030, 1, 10, 10, 0) do
      described_class.call(providers: providers_relation, date: Date.current)
    end

    expect(previous.reload).to be_closed_at
    expect(provider_notifications.active.sole.created_at.to_date).to eq(Date.new(2030, 1, 10))
    expect(provider_notifications.count).to eq(2)
  end

  it "uses Notifier with the provider as recipient and notifiable" do
    allow(Notifier).to receive(:call)

    call_notifier

    expect(Notifier).to have_received(:call).with(
      event_key: :provider_menu_unpublished,
      user: provider.user,
      notifiable: provider,
      description_data: { date: "9/1/2030" }
    )
  end

  it "registers a configurable provider event that requires action" do
    event = Notification::Registry.event!(:provider_menu_unpublished)
    configuration = Notification::Registry.configurations.fetch(:menu_publication_reminders)

    expect(event).to have_attributes(
      configuration_key: :menu_publication_reminders,
      role: :provider,
      requires_action: true
    )
    expect(configuration).to have_attributes(roles: [ :provider ], configurable: true)
  end
end
