# frozen_string_literal: true

require "rails_helper"

RSpec.describe DebtReminders::EmployeeEligibility do
  fixtures :users, :companies, :consumers, :providers, :accounts, :payments

  let(:consumer) { consumers(:one) }
  let(:overdue_day) { accounts(:one_tuviandita_current).due_date + 1.day }

  describe "#overdue_accounts" do
    it "junta todas las cuentas vencidas e impagas del empleado" do
      travel_to overdue_day do
        eligibility = described_class.new(consumer:)

        expect(eligibility.overdue_accounts).to contain_exactly(
          accounts(:one_tuviandita_current),
          accounts(:one_endulzate_current)
        )
        expect(eligibility.amount).to eq(950.75)
      end
    end

    it "deja afuera las que todavía no vencieron" do
      travel_to accounts(:one_tuviandita_current).due_date - 1.day do
        expect(described_class.new(consumer:).overdue_accounts).to be_empty
      end
    end

    it "deja afuera las que tienen un comprobante esperando revisión" do
      travel_to overdue_day do
        accounts(:one_endulzate_current).payments.create!(status: :pending)
        Payment.where(account: accounts(:one_tuviandita_current)).update_all(status: Payment.statuses[:submitted])

        expect(described_class.new(consumer:).overdue_accounts)
          .to contain_exactly(accounts(:one_endulzate_current))
      end
    end
  end

  describe "#provider_names" do
    it "nombra a cada proveedor con deuda vencida, una sola vez y en orden" do
      consumer.accounts.create!(provider: providers(:tuviandita), month: 2.months.ago.beginning_of_month, amount: 300)

      travel_to overdue_day do
        expect(described_class.new(consumer:).provider_names).to eq([ "Other Provider User", "Provider User" ])
      end
    end

    it "devuelve solo un proveedor cuando el empleado solo le debe a uno" do
      accounts(:one_endulzate_current).destroy!

      travel_to overdue_day do
        expect(described_class.new(consumer:).provider_names).to eq([ "Provider User" ])
      end
    end

    it "usa un genérico cuando el proveedor se quedó sin usuario" do
      providers(:endulzate).update_columns(user_id: nil)

      travel_to overdue_day do
        expect(described_class.new(consumer:).provider_names).to eq([ "Provider User", "un proveedor" ])
      end
    end

    it "usa un genérico cuando el nombre del usuario está en blanco" do
      providers(:endulzate).user.update_columns(name: "   ")

      travel_to overdue_day do
        expect(described_class.new(consumer:).provider_names).to eq([ "Provider User", "un proveedor" ])
      end
    end

    it "no duplica el genérico cuando varios proveedores están sin usuario" do
      providers(:tuviandita).update_columns(user_id: nil)
      providers(:endulzate).update_columns(user_id: nil)

      travel_to overdue_day do
        expect(described_class.new(consumer:).provider_names).to eq([ "un proveedor" ])
      end
    end
  end

  describe "#reason" do
    it "no bloquea cuando hay deuda vencida y nunca se mandó un recordatorio" do
      travel_to overdue_day do
        expect(described_class.new(consumer:)).to be_eligible
      end
    end

    it "bloquea por no_debt cuando no hay nada vencido" do
      travel_to accounts(:one_tuviandita_current).due_date - 1.day do
        expect(described_class.new(consumer:).reason).to eq(:no_debt)
      end
    end

    it "bloquea por cooldown durante los tres días siguientes al último envío" do
      travel_to overdue_day do
        send_reminder

        expect(described_class.new(consumer:).reason).to eq(:cooldown)
      end
    end

    it "vuelve a habilitar pasados los tres días" do
      travel_to overdue_day do
        send_reminder
      end

      travel_to overdue_day + DebtReminders::Eligibility::COOLDOWN + 1.hour do
        expect(described_class.new(consumer:)).to be_eligible
      end
    end

    it "bloquea por limit_reached al llegar al tope de recordatorios" do
      travel_to overdue_day do
        DebtReminders::Eligibility::MAX_REMINDERS.times { send_reminder }
      end

      travel_to overdue_day + 1.year do
        eligibility = described_class.new(consumer:)

        expect(eligibility.reason).to eq(:limit_reached)
        expect(eligibility.remaining).to eq(0)
      end
    end
  end

  # Las notificaciones se crean a mano para no depender del servicio de envío.
  def send_reminder
    Notification.create!(
      notification_configuration: configuration,
      user: consumer.user,
      role: "consumer",
      event: described_class::EVENT,
      requires_action: false,
      notifiable: consumer,
      description_data: {amount: "INF", providers: "TuViandia"}
    ).tap(&:close!)
  end

  def configuration
    @configuration ||= Notification::Configuration.find_or_create_by!(key: "hr_payment_reminders") do |config|
      config.roles = [ "consumer" ]
    end
  end
end
