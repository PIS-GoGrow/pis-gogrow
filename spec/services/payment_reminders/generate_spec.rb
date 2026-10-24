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
      expect(notification.description).to include("martes 10 de noviembre")
    end

    describe "payment period opening notice" do
      let(:opening_day) { Date.new(2026, 11, 1) }
      let(:other_provider_account) { accounts(:one_endulzate_current) }

      def opening_notices
        Notification.where(event: "payment_available")
      end

      before do
        other_provider_account.payments.destroy_all
        other_provider_account.update!(month: Date.new(2026, 10, 1), amount: 800)
      end

      [ Date.new(2026, 10, 31), Date.new(2026, 11, 2) ].each do |date|
        it "is not created on #{date}, one day off the first of the month" do
          expect {
            described_class.call(date:)
          }.not_to change { opening_notices.count }
        end
      end

      it "tells the employee they can review the payment detail" do
        described_class.call(date: opening_day)

        expect(opening_notices.find_by!(notifiable: account).description)
          .to include("Revisá el detalle de tu pago")
      end

      it "is created once per provider the employee owes" do
        described_class.call(date: opening_day)

        expect(opening_notices.where(user:).pluck(:notifiable_id))
          .to contain_exactly(account.id, other_provider_account.id)
        expect(opening_notices.find_by!(notifiable: other_provider_account).description)
          .to include(other_provider_account.provider.user.name)
      end

      it "is not created for a provider the employee owes nothing to" do
        other_provider_account.update!(amount: 0)

        described_class.call(date: opening_day)

        expect(opening_notices.where(notifiable: other_provider_account)).to be_empty
      end

      it "is not created for the month still in progress" do
        other_provider_account.update!(month: Date.new(2026, 11, 1))

        described_class.call(date: opening_day)

        expect(opening_notices.where(notifiable: other_provider_account)).to be_empty
      end

      it "is only created for the provider whose payment is still pending" do
        other_provider_account.payments.create!(provider: other_provider_account.provider, status: :approved)

        described_class.call(date: opening_day)

        expect(opening_notices.where(user:).pluck(:notifiable_id)).to eq([ account.id ])
      end

      it "is not created while a receipt is under review" do
        payment = account.payments.create!(provider: account.provider, status: :pending)
        payment.update_column(:status, Payment.statuses[:submitted])

        described_class.call(date: opening_day)

        expect(opening_notices.where(notifiable: account)).to be_empty
      end

      it "is created when the last payment was rejected" do
        account.payments.create!(
          provider: account.provider,
          status: :rejected,
          rejection_reason: "El comprobante no se lee"
        )

        described_class.call(date: opening_day)

        expect(opening_notices.where(notifiable: account).count).to eq(1)
      end

      it "is not created again after the employee dismisses it" do
        described_class.call(date: opening_day)
        opening_notices.find_by!(notifiable: account).close!

        expect {
          described_class.call(date: opening_day)
        }.not_to change { opening_notices.where(notifiable: account).count }
      end
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
      expect(notification.description).to include("martes 10 de noviembre")
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
