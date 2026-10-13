# frozen_string_literal: true

require "rails_helper"

RSpec.describe PaymentReminders::Generate do
  fixtures :users, :companies, :providers, :consumers, :accounts, :payments

  let(:account) { accounts(:one_tuviandita_current) }
  let(:consumer) { account.owner }
  let(:user) { consumer.user }

  before do
    Notification::Configuration.find_or_create_by!(key: "automatic_payment_reminders") do |configuration|
      configuration.roles = [ "consumer" ]
    end

    account.payments.destroy_all
    account.update!(
      month: Date.new(2026, 10, 1),
      amount: 1_500
    )
  end

  describe ".call" do
    it "notifies when the payment period becomes available" do
      expect {
        described_class.call(date: Date.new(2026, 11, 1))
      }.to change {
        Notification.where(
          user:,
          notifiable: account,
          event: "payment_available"
        ).count
      }.by(1)

      notification = Notification.find_by!(
        user:,
        notifiable: account,
        event: "payment_available"
      )

      expect(notification).to have_attributes(
        user:,
        notifiable: account,
        event: "payment_available",
        requires_action: false
      )
      expect(notification.description).to include("$1.500")
      expect(notification.description).to include(account.provider.user.name)
      expect(notification.description).to include("10/11/2026")
    end

    it "notifies three days before the due date" do
      expect {
        described_class.call(date: Date.new(2026, 11, 7))
      }.to change {
        Notification.where(
          user:,
          notifiable: account,
          event: "payment_due_soon"
        ).count
      }.by(1)

      notification = Notification.find_by!(
        user:,
        notifiable: account,
        event: "payment_due_soon"
      )

      expect(notification).to have_attributes(
        user:,
        notifiable: account,
        event: "payment_due_soon",
        requires_action: false
      )
      expect(notification.description).to include("3 días")
      expect(notification.description).to include("10/11/2026")
      expect(notification.description).to include("$1.500")
      expect(notification.description).to include(account.provider.user.name)
      expect(notification.description).to include("Revisá el detalle de tu pago")
    end

    [ Date.new(2026, 11, 6), Date.new(2026, 11, 8) ].each do |date|
      it "does not notify the due date on #{date}, one day off the reminder day" do
        expect {
          described_class.call(date:)
        }.not_to change {
          Notification.where(notifiable: account, event: "payment_due_soon").count
        }
      end
    end

    it "does not duplicate the due date reminder when it runs twice on the same day" do
      date = Date.new(2026, 11, 7)

      described_class.call(date:)

      expect {
        described_class.call(date:)
      }.not_to change {
        Notification.where(user:, notifiable: account, event: "payment_due_soon").count
      }
    end

    it "notifies each employee about their own payment, once per provider" do
      other_account = accounts(:other_tuviandita_current)
      other_provider_account = accounts(:one_endulzate_current)
      [ other_account, other_provider_account ].each do |a|
        a.payments.destroy_all
        a.update!(month: Date.new(2026, 10, 1), amount: 800)
      end

      described_class.call(date: Date.new(2026, 11, 7))

      reminders = Notification.where(event: "payment_due_soon")
      expect(reminders.where(notifiable: account).pluck(:user_id)).to eq([ user.id ])
      expect(reminders.where(notifiable: other_account).pluck(:user_id)).to eq([ other_account.owner.user.id ])
      expect(reminders.where(notifiable: other_provider_account).pluck(:user_id)).to eq([ user.id ])
      expect(reminders.find_by!(notifiable: other_provider_account).description)
        .to include(other_provider_account.provider.user.name)
    end

    it "still notifies when the last payment was rejected, since it is pending again" do
      account.payments.create!(
        provider: account.provider,
        status: :rejected,
        rejection_reason: "El comprobante no se lee"
      )

      expect {
        described_class.call(date: Date.new(2026, 11, 7))
      }.to change {
        Notification.where(user:, notifiable: account, event: "payment_due_soon").count
      }.by(1)
    end

    it "does not notify on another day" do
      expect {
        described_class.call(date: Date.new(2026, 11, 5))
      }.not_to change {
        Notification.where(notifiable: account).count
      }
    end

    it "does not duplicate the payment available notification" do
      date = Date.new(2026, 11, 1)

      described_class.call(date:)

      expect {
        described_class.call(date:)
      }.not_to change {
        Notification.where(
          user:,
          notifiable: account,
          event: "payment_available"
        ).count
      }
    end

    it "does not recreate a notification after the employee dismisses it" do
      date = Date.new(2026, 11, 7)

      described_class.call(date:)

      notification = Notification.find_by!(
        user:,
        notifiable: account,
        event: "payment_due_soon"
      )
      notification.close!

      expect {
        described_class.call(date:)
      }.not_to change {
        Notification.where(
          user:,
          notifiable: account,
          event: "payment_due_soon"
        ).count
      }
    end

    it "does not notify while a payment is under review" do
      payment = account.payments.create!(
        provider: account.provider,
        status: :pending
      )

      payment.update_column(:status, Payment.statuses[:submitted])

      expect {
        described_class.call(date: Date.new(2026, 11, 7))
      }.not_to change {
        Notification.where(notifiable: account).count
      }
    end

    it "does not notify an approved account" do
      account.payments.create!(
        provider: account.provider,
        status: :approved
      )

      expect {
        described_class.call(date: Date.new(2026, 11, 7))
      }.not_to change {
        Notification.where(notifiable: account).count
      }
    end
  end
end
