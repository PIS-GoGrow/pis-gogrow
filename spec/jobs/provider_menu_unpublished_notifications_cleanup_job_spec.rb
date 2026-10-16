# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProviderMenuUnpublishedNotificationsCleanupJob, type: :job do
  fixtures :users, :providers

  let(:provider) { providers(:tuviandita) }
  let(:event) { Menus::MissingPublicationNotifier::EVENT }

  before { travel_to Time.zone.local(2030, 1, 11, 10, 0) }

  def create_reminder
    Notifier.call(
      event_key: event,
      user: provider.user,
      notifiable: provider,
      description_data: { date: I18n.l(Date.current) }
    )
  end

  it "closes notifications from the previous date after the day changes" do
    notification = create_reminder

    travel_to Time.zone.local(2030, 1, 12, 0, 5)
    described_class.perform_now

    expect(notification.reload).to be_closed_at
  end

  it "keeps Friday notifications closed throughout the weekend without creating new ones" do
    notification = create_reminder

    travel_to Time.zone.local(2030, 1, 12, 0, 5)
    described_class.perform_now
    travel_to Time.zone.local(2030, 1, 13, 0, 5)
    described_class.perform_now

    expect(notification.reload).to be_closed_at
    expect(provider.user.notifications.where(event:).count).to eq(1)
  end
end
