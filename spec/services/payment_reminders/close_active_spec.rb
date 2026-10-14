# frozen_string_literal: true

require "rails_helper"

RSpec.describe PaymentReminders::CloseActive do
  fixtures :users, :companies, :providers, :consumers, :accounts

  let(:account) { accounts(:one_tuviandita_current) }
  let(:user) { account.owner.user }

  before do
    Notification::Configuration.find_or_create_by!(
      key: "automatic_payment_reminders"
    ) do |configuration|
      configuration.roles = [ "consumer" ]
    end

    Notification::Configuration.find_or_create_by!(
      key: "provider_payment_reminders"
    ) do |configuration|
      configuration.roles = [ "consumer" ]
    end
  end

  it "closes active automatic reminders for the account" do
    available = Notifier.call(
      event_key: "payment_available",
      user:,
      notifiable: account,
      description_data: {
        amount: "$1.500",
        provider: account.provider.user.name,
        due_date: "10/11/2026"
      }
    )

    due_soon = Notifier.call(
      event_key: "payment_due_soon",
      user:,
      notifiable: account,
      description_data: {
        amount: "$1.500",
        provider: account.provider.user.name,
        due_date: "10/11/2026",
        days: 3
      }
    )

    described_class.call(account:)

    expect(available.reload.closed_at).to be_present
    expect(due_soon.reload.closed_at).to be_present
  end

  it "does not close the provider manual debt reminder" do
    notification = Notifier.call(
      event_key: "debt_payment_reminder",
      user:,
      notifiable: account,
      description_data: {
        amount: "$1.500",
        provider: account.provider.user.name,
        period: "octubre de 2026"
      }
    )

    described_class.call(account:)

    expect(notification.reload.closed_at).to be_nil
  end
end
