# frozen_string_literal: true

require "rails_helper"

RSpec.describe DebtReminders::EmployeeRequest do
  fixtures :users, :companies, :consumers, :providers, :accounts, :payments, :admins

  let(:consumer) { consumers(:one) }
  let(:admin_user) { users(:admin) }
  let(:overdue_day) { accounts(:one_tuviandita_current).due_date + 1.day }

  before do
    Notification::Configuration.find_or_create_by!(key: "hr_payment_reminders") do |config|
      config.roles = [ "consumer" ]
    end
  end

  describe ".call" do
    it "crea una única notificación con la deuda vencida sumada" do
      travel_to overdue_day do
        expect {
          described_class.call(consumer:, requested_by: admin_user)
        }.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.user).to eq(consumer.user)
        expect(notification.event).to eq(DebtReminders::EmployeeEligibility::EVENT)
        expect(notification.notifiable).to eq(consumer)
        expect(notification.requires_action).to be(false)
        expect(notification.description).to include("$950,75")
      end
    end

    it "nombra a los proveedores a los que les debe" do
      travel_to overdue_day do
        notification = described_class.call(consumer:, requested_by: admin_user)

        expect(notification.description).to include("con Other Provider User y Provider User.")
      end
    end

    it "nombra una sola vez al proveedor que tiene varias cuentas vencidas" do
      consumer.accounts.create!(provider: providers(:tuviandita), month: 2.months.ago.beginning_of_month, amount: 300)

      travel_to overdue_day do
        notification = described_class.call(consumer:, requested_by: admin_user)

        expect(notification.description).to include("con Other Provider User y Provider User.")
        expect(notification.description).to include("$1.250,75")
      end
    end

    it "no deja reclamarle a un empleado de otra empresa" do
      other_company = Company.create!(name: "Otra empresa", address: "Rincón 500")
      other_user = User.create!(name: "Ajeno", email: "ajeno@example.com", password: "Secret1*3*5*")
      other_consumer = Consumer.create!(company: other_company, user: other_user, address: "Yí 1234")

      travel_to overdue_day do
        expect {
          described_class.call(consumer: other_consumer, requested_by: admin_user)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it "rechaza el envío mientras corre la espera de tres días" do
      travel_to overdue_day do
        described_class.call(consumer:, requested_by: admin_user)

        expect {
          described_class.call(consumer:, requested_by: admin_user)
        }.to raise_error(DebtReminders::Request::Ineligible) { |error| expect(error.reason).to eq(:cooldown) }
      end
    end

    it "reemplaza el recordatorio anterior en lugar de acumularlos" do
      first = travel_to(overdue_day) { described_class.call(consumer:, requested_by: admin_user) }

      travel_to overdue_day + DebtReminders::Eligibility::COOLDOWN + 1.hour do
        described_class.call(consumer:, requested_by: admin_user)

        expect(first.reload.closed_at).to be_present
        expect(consumer.user.notifications.active.count).to eq(1)
      end
    end

    it "rechaza el envío cuando el empleado no tiene deuda vencida" do
      travel_to accounts(:one_tuviandita_current).due_date - 1.day do
        expect {
          described_class.call(consumer:, requested_by: admin_user)
        }.to raise_error(DebtReminders::Request::Ineligible) { |error| expect(error.reason).to eq(:no_debt) }
      end
    end
  end

  describe ".close_if_settled" do
    it "cierra el recordatorio cuando ya no queda deuda vencida" do
      travel_to overdue_day do
        notification = described_class.call(consumer:, requested_by: admin_user)
        consumer.accounts.update_all(amount: 0)

        described_class.close_if_settled(consumer)

        expect(notification.reload.closed_at).to be_present
      end
    end

    it "lo deja abierto mientras siga debiendo algo" do
      travel_to overdue_day do
        notification = described_class.call(consumer:, requested_by: admin_user)

        described_class.close_if_settled(consumer)

        expect(notification.reload.closed_at).to be_nil
      end
    end

    it "se dispara solo al aprobarse el pago que salda la última cuenta" do
      travel_to overdue_day do
        notification = described_class.call(consumer:, requested_by: admin_user)
        consumer.accounts.update_all(amount: 0)
        payment = accounts(:one_tuviandita_current).payments.create!(status: :pending)

        payment.approve

        expect(notification.reload.closed_at).to be_present
      end
    end
  end
end
