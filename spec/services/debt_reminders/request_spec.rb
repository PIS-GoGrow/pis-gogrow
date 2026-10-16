# frozen_string_literal: true

require "rails_helper"

RSpec.describe DebtReminders::Request do
  fixtures :users, :companies, :providers, :consumers, :accounts, :payments

  let(:provider) { providers(:tuviandita) }
  let(:provider_user) { users(:provider_user) }
  let(:other_provider_user) { users(:other_provider_user) }
  let(:consumer_account) { accounts(:one_tuviandita_current) }
  let(:consumer_user) { users(:one) }

  before do
    Notification::Configuration.find_or_create_by!(key: "provider_payment_reminders") do |c|
      c.roles = [ "consumer" ]
    end
    consumer_account.update!(amount: 150)
  end

  describe ".call" do
    it "crea una notificación para el empleado y cierra notificaciones activas previas" do
      start_time = consumer_account.due_date + 1.day
      prev_notification = nil

      travel_to start_time do
        prev_notification = Notifier.call(
          event_key: DebtReminders::Eligibility::EVENT,
          user: consumer_user,
          notifiable: consumer_account,
          description_data: { amount: "$150", provider: provider.user.name, period: "octubre 2026" }
        )
      end
      expect(prev_notification.closed_at).to be_nil

      # Viajar a 4 días después del inicio para superar el cooldown de 3 días
      travel_to start_time + 4.days do
        notification = nil
        expect {
          notification = described_class.call(account: consumer_account, requested_by: provider_user)
        }.to change(Notification, :count).by(1)

        expect(notification.user).to eq(consumer_user)
        expect(notification.event).to eq(DebtReminders::Eligibility::EVENT)
        expect(notification.notifiable).to eq(consumer_account)
        expect(notification.closed_at).to be_nil

        # Verifica que la anterior fue cerrada
        expect(prev_notification.reload.closed_at).to be_present
      end
    end

    it "lanza ActiveRecord::RecordNotFound si el usuario no es el proveedor dueño de la cuenta" do
      travel_to consumer_account.due_date + 1.day do
        expect {
          described_class.call(account: consumer_account, requested_by: other_provider_user)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it "lanza DebtReminders::Request::Ineligible si la cuenta no es elegible" do
      # Cuenta no vencida
      travel_to consumer_account.due_date - 1.day do
        expect {
          described_class.call(account: consumer_account, requested_by: provider_user)
        }.to raise_error(DebtReminders::Request::Ineligible) do |error|
          expect(error.reason).to eq(:not_overdue)
        end
      end
    end

    it "lanza DebtReminders::Request::CreationFailed si Notifier no devuelve notificación" do
      travel_to consumer_account.due_date + 1.day do
        allow(Notifier).to receive(:call).and_return(nil)
        expect {
          described_class.call(account: consumer_account, requested_by: provider_user)
        }.to raise_error(DebtReminders::Request::CreationFailed)
      end
    end

    it "evita crear notificaciones duplicadas ante llamadas consecutivas en cooldown" do
      travel_to consumer_account.due_date + 1.day do
        expect {
          described_class.call(account: consumer_account, requested_by: provider_user)
        }.to change(Notification, :count).by(1)

        expect {
          described_class.call(account: consumer_account, requested_by: provider_user)
        }.to raise_error(DebtReminders::Request::Ineligible) do |error|
          expect(error.reason).to eq(:cooldown)
        end
      end
    end
  end
end
