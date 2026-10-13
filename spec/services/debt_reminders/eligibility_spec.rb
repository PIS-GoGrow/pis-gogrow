# frozen_string_literal: true

require "rails_helper"

RSpec.describe DebtReminders::Eligibility do
  fixtures :users, :companies, :providers, :consumers, :accounts, :payments

  let(:consumer_account) { accounts(:one_tuviandita_current) }
  let(:company_account) { accounts(:gogrow_tuviandita_current) }
  let(:consumer_user) { users(:one) }

  describe "#eligible?" do
    it "devuelve true para una cuenta de consumidor con deuda vencida y sin recordatorios recientes" do
      consumer_account.update!(amount: 100)
      # due_date = month + 1.month + 4.days
      # Para que esté vencida hoy, viajamos a después de due_date
      travel_to consumer_account.due_date + 1.day do
        eligibility = described_class.new(account: consumer_account)
        expect(eligibility.eligible?).to be true
        expect(eligibility.reason).to be_nil
      end
    end
  end

  describe "#reason" do
    it "devuelve :not_consumer cuando la cuenta pertenece a una empresa" do
      eligibility = described_class.new(account: company_account)
      expect(eligibility.reason).to eq(:not_consumer)
    end

    it "devuelve :no_debt cuando el monto es menor o igual a cero" do
      consumer_account.update!(amount: 0)
      travel_to consumer_account.due_date + 1.day do
        eligibility = described_class.new(account: consumer_account)
        expect(eligibility.reason).to eq(:no_debt)
      end
    end

    it "devuelve :not_overdue cuando la fecha de vencimiento aún no pasó" do
      consumer_account.update!(amount: 150)
      travel_to consumer_account.due_date - 1.day do
        eligibility = described_class.new(account: consumer_account)
        expect(eligibility.reason).to eq(:not_overdue)
      end
    end

    it "devuelve :payment_under_review cuando la cuenta tiene comprobante enviado en revisión (submitted)" do
      submitted_account = accounts(:other_tuviandita_current)
      submitted_account.update!(amount: 150)
      travel_to submitted_account.due_date + 1.day do
        eligibility = described_class.new(account: submitted_account)
        expect(eligibility.reason).to eq(:payment_under_review)
      end
    end

    it "devuelve :paid cuando la cuenta tiene un pago aprobado" do
      consumer_account.update!(amount: 150)
      consumer_account.payments.create!(provider: consumer_account.provider, status: :approved)
      travel_to consumer_account.due_date + 1.day do
        eligibility = described_class.new(account: consumer_account)
        expect(eligibility.reason).to eq(:paid)
      end
    end

    def create_reminder_notification(at:, closed: true)
      configuration = Notification::Configuration.find_or_create_by!(key: "provider_payment_reminders") do |c|
        c.roles = [ "consumer" ]
      end

      notification = Notification.new(
        user: consumer_user,
        notification_configuration: configuration,
        event: described_class::EVENT,
        notifiable: consumer_account,
        title: "Recordatorio de pago",
        description: "Tienes una deuda pendiente",
        role: "consumer",
        requires_action: false,
        closed_at: closed ? at : nil
      )
      notification.save!(validate: false)
      notification.update_column(:created_at, at)
      notification
    end

    it "devuelve :limit_reached cuando ya se enviaron 10 recordatorios" do
      consumer_account.update!(amount: 150)
      10.times do |i|
        create_reminder_notification(at: (40 - (i * 4)).days.ago)
      end

      travel_to consumer_account.due_date + 1.day do
        eligibility = described_class.new(account: consumer_account)
        expect(eligibility.sent_count).to eq(10)
        expect(eligibility.remaining).to eq(0)
        expect(eligibility.reason).to eq(:limit_reached)
      end
    end

    it "devuelve :cooldown cuando el último recordatorio fue hace menos de 3 días" do
      consumer_account.update!(amount: 150)
      reference_date = consumer_account.due_date + 10.days
      create_reminder_notification(at: reference_date - 1.day)

      travel_to reference_date do
        eligibility = described_class.new(account: consumer_account)
        expect(eligibility.reason).to eq(:cooldown)
        expect(eligibility.next_available_at).to be_present
      end
    end

    it "permite enviar cuando el último recordatorio fue hace más de 3 días" do
      consumer_account.update!(amount: 150)
      reference_date = consumer_account.due_date + 10.days
      create_reminder_notification(at: reference_date - 4.days)

      travel_to reference_date do
        eligibility = described_class.new(account: consumer_account)
        expect(eligibility.reason).to be_nil
        expect(eligibility.eligible?).to be true
      end
    end
  end
end
